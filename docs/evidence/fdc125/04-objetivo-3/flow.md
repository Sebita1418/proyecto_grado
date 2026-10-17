# Flujo implementado

```mermaid
flowchart TD
 A[GPS o candidato elegido y modos locales] --> B[Validación de OD y territorio]
 B --> C[ModeRoutingService: grafo por modo]
 C --> D[OSRM: geometría y métricas validadas]
 D --> E{Vehículo y Ahora}
 R[Reportes activos Supabase, snapshot máximo 100] --> F[Proximidad a segmentos hasta 125 m]
 E -->|Sí| F
 F --> G[Grupo comparable: duración x1.25 y distancia x1.5]
 G --> H[Cierres reportados, conteos, tiempo, distancia, orden]
 H --> I[Sugerencia y razones; elección del usuario separada]
 E -->|Caminar o bicicleta| J[Consulta y elección; sin ranking entre modos]
 K[Historial RPC general hasta 30 días y 5000 filas] --> L[Calidad, calendario Bogotá y suficiencia]
 L --> M[Franjas descriptivas o abstención; no predicción]
```

Las ramas histórica y vehicular no forman un optimizador conjunto. Configuración remota de RPC y Realtime no queda acreditada por los fixtures. Véanse [funciones y casos](README.md).
