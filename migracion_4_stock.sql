-- Forzar la eliminación de la función vieja para evitar el error 42P13 sin tocar datos
DROP FUNCTION IF EXISTS registrar_venta(jsonb, bigint);
DROP FUNCTION IF EXISTS registrar_venta(jsonb);

-- Crear la versión definitiva e inmune a condiciones de carrera
CREATE OR REPLACE FUNCTION registrar_venta(
    items jsonb,
    cliente_id bigint DEFAULT NULL
) RETURNS void AS $$
DECLARE
    item jsonb;
    p_id bigint;
    p_cant int;
    p_precio numeric;
    p_nombre text;
    v_id bigint;
    v_total numeric := 0;
    actual_stock int;
BEGIN
    -- 1. Crear la cabecera de la venta temporalmente a $0
    INSERT INTO ventas (cliente_id, total, vendedor_id)
    VALUES (cliente_id, 0, auth.uid())
    RETURNING id INTO v_id;

    -- 2. Iterar por cada producto del carrito
    FOR item IN SELECT * FROM jsonb_array_elements(items) LOOP
        p_id := (item->>'producto_id')::bigint;
        p_cant := (item->>'cantidad')::int;

        -- OBTENER DETALLES Y BLOQUEAR FILA PARA EVITAR CONDICIÓN DE CARRERA
        SELECT stock, precio, nombre 
        INTO actual_stock, p_precio, p_nombre
        FROM productos 
        WHERE id = p_id 
        FOR UPDATE;

        -- VALIDACIÓN CRÍTICA DE STOCK EN TIEMPO REAL
        IF actual_stock < p_cant THEN
            RAISE EXCEPTION 'STOCK_INSUFICIENTE: No hay suficiente stock de %. Disponible: %, Solicitado: %', 
                p_nombre, actual_stock, p_cant;
        END IF;

        -- 3. Descontar stock inmediatamente
        UPDATE productos 
        SET stock = stock - p_cant 
        WHERE id = p_id;

        -- 4. Registrar en el detalle de la venta
        INSERT INTO venta_detalle (venta_id, producto_id, cantidad, precio_unitario, producto_nombre)
        VALUES (v_id, p_id, p_cant, p_precio, p_nombre);

        -- Acumular el total
        v_total := v_total + (p_precio * p_cant);
    END LOOP;

    -- 5. Actualizar el total definitivo de la venta
    UPDATE ventas 
    SET total = v_total 
    WHERE id = v_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
