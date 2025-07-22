# Diagnóstico de Filtros - Visualización por Pasillo

## 🔍 Pasos para Diagnosticar los Problemas

### 1. **Verificar que el JavaScript se carga correctamente**

1. Abre la página de visualización por pasillo en tu navegador
2. Abre las herramientas de desarrollo (F12)
3. Ve a la pestaña "Console" (Consola)
4. Deberías ver estos mensajes:
   - `🏥 Sistema de visualización de pasillos cargado correctamente`
   - `✅ Funciones registradas: [objeto con las funciones]`

### 2. **Probar las funciones manualmente**

En la consola del navegador, ejecuta estos comandos uno por uno:

```javascript
// Verificar que las funciones existen
console.log(typeof window.aplicarFiltrosPasillo);
console.log(typeof window.buscarPorMedicoPasillo);
console.log(typeof window.buscarPorBoxPasillo);

// Probar la función principal
window.aplicarFiltrosPasillo();
```

### 3. **Verificar que los elementos HTML existen**

```javascript
// Verificar que los elementos existen
console.log(document.getElementById('pasillo'));
console.log(document.getElementById('fecha'));
console.log(document.getElementById('jornada'));
console.log(document.getElementById('codigoMedico'));
console.log(document.getElementById('codigoBox'));
```

### 4. **Probar un filtro específico**

```javascript
// Establecer un valor y aplicar filtro
document.getElementById('pasillo').value = '1'; // Ajusta el valor según tus datos
window.aplicarFiltrosPasillo();
```

### 5. **Verificar errores en la consola**

- Si hay errores en rojo en la consola, cópialos y compártelos
- Si no hay errores pero los filtros no funcionan, continúa con el siguiente paso

### 6. **Verificar la URL actual**

```javascript
// Ver la URL actual
console.log(window.location.href);

// Ver los parámetros actuales
console.log(new URLSearchParams(window.location.search));
```

## 🚨 Posibles Problemas y Soluciones

### Problema 1: "aplicarFiltrosPasillo is not defined"
**Solución**: El JavaScript no se está cargando correctamente.
- Verifica que el archivo `visualizacionPasillo.js` esté en la ruta correcta
- Verifica que esté incluido en el template HTML

### Problema 2: Los elementos no existen (null)
**Solución**: Los IDs no coinciden o el HTML no está cargado.
- Verifica que los elementos tengan los IDs correctos
- Verifica que el JavaScript se ejecute después de cargar el DOM

### Problema 3: La función se ejecuta pero no navega
**Solución**: Problema con la construcción de la URL.
- Verifica que la URL generada sea correcta
- Verifica que no haya caracteres especiales que causen problemas

### Problema 4: La página se recarga pero los filtros no se aplican
**Solución**: El backend no está procesando los parámetros.
- Verifica que la vista Django esté recibiendo los parámetros correctamente
- Verifica que los nombres de los parámetros coincidan entre frontend y backend

## 📋 Información a Recopilar

Si los problemas persisten, proporciona esta información:

1. **Mensajes de la consola**: Copia todos los mensajes, incluyendo errores
2. **Resultado de las verificaciones**: Qué devuelven las funciones de verificación
3. **URL actual**: Antes y después de intentar aplicar filtros
4. **Versión del navegador**: Qué navegador estás usando
5. **Errores del servidor**: Si hay errores en el servidor Django

## 🔧 Comandos de Prueba Rápida

Copia y pega este bloque completo en la consola:

```javascript
console.log('=== DIAGNÓSTICO DE FILTROS ===');
console.log('1. Funciones disponibles:', {
    aplicarFiltrosPasillo: typeof window.aplicarFiltrosPasillo,
    buscarPorMedicoPasillo: typeof window.buscarPorMedicoPasillo,
    buscarPorBoxPasillo: typeof window.buscarPorBoxPasillo
});

console.log('2. Elementos HTML:', {
    pasillo: !!document.getElementById('pasillo'),
    fecha: !!document.getElementById('fecha'),
    jornada: !!document.getElementById('jornada'),
    codigoMedico: !!document.getElementById('codigoMedico'),
    codigoBox: !!document.getElementById('codigoBox')
});

console.log('3. URL actual:', window.location.href);
console.log('4. Parámetros actuales:', Object.fromEntries(new URLSearchParams(window.location.search)));

console.log('=== FIN DIAGNÓSTICO ===');
```

## 📞 Siguiente Paso

Ejecuta el diagnóstico y comparte los resultados. Con esa información podré identificar exactamente qué está fallando y cómo solucionarlo.
