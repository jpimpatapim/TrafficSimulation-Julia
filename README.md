# Simulación de Tráfico: Ondas de Choque en Julia

Este proyecto simula el comportamiento de un flujo vehicular en una vía de un solo carril, demostrando cómo una frenada repentina del líder genera una **onda de choque** que se propaga hacia atrás.

## Características
* **Modelo de Seguimiento:** Implementa una regla de seguridad de 2 segundos + 5 metros.
* **Visualización:** Genera un *Heatmap* dinámico basado en la velocidad de los vehículos.
* **Análisis de Datos:** Calcula automáticamente la caída de velocidad y el tiempo de recuperación del sistema.

## Visualización
![Simulación de Tráfico](/results/trafico_sim.gif)

## Requisitos
Necesitas tener instalado [Julia](https://julialang.org/) y las siguientes librerías:
* `Plots`
* `Interpolations`
* `Printf`
* `Statistics`

## Cómo ejecutar
1. Clona este repositorio.
2. Abre la terminal en la carpeta del proyecto.
3. Ejecuta:
   ```bash
   julia src/simulacion_trafico.jl

## Instalar dependencias
Para ejecutar esta simulación con las versiones exactas de las librerías, clona el repositorio y en la consola de Julia ejecuta:

```julia
	using Pkg
	Pkg.activate(".")
	Pkg.instantiate()
