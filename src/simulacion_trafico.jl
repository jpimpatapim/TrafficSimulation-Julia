# --- LIBRERÍAS, CONSTANTES Y ESTRUCTURAS ---
using Plots, Interpolations, Printf, Statistics

gr() # Backend de Plots (Sugerido por IA)

# Constantes			    Unidades de medida
const VEL_DESEADA = 40.0    # m/s
const LONGITUD_CARRO = 2.0  # m
const ACEL_MAX = 1.5        # m/s^2
const FRENADO_EMERG = 9.0   # m/s^2
const DT = 0.1              # s
const VIA_LON = 800.0       # m
const T_FRENO_INICIO = 5.0  # s 
const T_FRENO_FIN = 12.0    # s 

# Estructuras
mutable struct Carro
    posicion::Float64
    velocidad::Float64
end

mutable struct SimulacionTrafico
    carros::Vector{Carro}
    tiempo::Float64
    historial_vel::Vector{Float64}
    historial_t::Vector{Float64}   
end

# Para facilitar la creacion de un objeto Carro
	Carro(pos, vel) = Carro(Float64(pos), Float64(vel))

# --- FUNCIONES ---
# Lógica del carro
function actualizar_carro!(c::Carro, c_adelante::Union{Carro, Nothing})
    if isnothing(c_adelante) # Si no hay nadie adelante el carro es líder
    
        if c.velocidad < VEL_DESEADA
		             
        elseif c.velocidad > VEL_DESEADA
            c.velocidad -= 1.0 * DT
        end
        
    else # De lo contario es un carro en fila
        distancia_real = c_adelante.posicion - c.posicion - LONGITUD_CARRO
        # Regla de los 2 segundos + 5 metros
        distancia_deseada = (c.velocidad * 2.0) + 5.0

		# Para evitar sobreposiciones / actúa como frenado de emergencia
        if distancia_real <= 1.0
            c.velocidad = 0.0	
            c.posicion = c_adelante.posicion - LONGITUD_CARRO - 1.0
            return
        end

        # Qué hacer dependiendo la distancia
        ratio = distancia_real / distancia_deseada
        if ratio >= 1.2 
            c.velocidad += ACEL_MAX * DT
        elseif 0.8 < ratio < 1.2
            c.velocidad += (c_adelante.velocidad - c.velocidad) * DT 
        else
            c.velocidad -= (FRENADO_EMERG * (1.0 - ratio)) * DT
        end
    end

    # Para evitar velocidades negativas
    if c.velocidad < 0.0; c.velocidad = 0.0; end
    
    c.posicion += c.velocidad * DT
end

# Para actualizar cada paso de la simulación
function paso_simulacion!(sim::SimulacionTrafico)
    sim.tiempo += DT

	#= Cálcular promedio de velocidad por cada paso de la simulación
	e insertarlo en el historial de la simulacion =#
    if !isempty(sim.carros)	
    	promedio = mean([c.velocidad for c in sim.carros])
    	push!(sim.historial_vel, promedio)
    	push!(sim.historial_t, sim.tiempo)
    end
    
    # Orden de los carros de izquierda a derecha

    # Insertar nuevos carros
    primer_carro = isempty(sim.carros) ? nothing : sim.carros[1]
    if isnothing(primer_carro) || primer_carro.posicion > 80.0
        vel_entrada = isnothing(primer_carro) ? 
        			  25.0 : min(25.0, primer_carro.velocidad)
        pushfirst!(sim.carros, Carro(0.0, vel_entrada))
    end

	# Filtrar carros que estan dentro de la longitud de la via
    filter!(c -> c.posicion < VIA_LON, sim.carros)

	# Frenado del líder
    if !isempty(sim.carros)
        lider = sim.carros[end]
        if T_FRENO_INICIO < sim.tiempo < T_FRENO_FIN
            lider.velocidad = max(0.0, lider.velocidad - 20.0 * DT)
            if lider.velocidad > 5.0; lider.velocidad = 5.0; end
        end
    end

	# Loop de actualización
    n = length(sim.carros)
    for i in 1:n
        c_adelante = (i == n) ? nothing : sim.carros[i+1]
        actualizar_carro!(sim.carros[i], c_adelante)
    end
end

# Inicializador
function iniciar_simulacion()
    carros = Vector{Carro}()
    sizehint!(carros, 50) # Para reservar memoria dedicada a la lista
    pos = VIA_LON - 50.0
    for _ in 1:25 # Para incertar los primeros 25 carros (con distancia 60)
        pushfirst!(carros, Carro(pos, 25.0))
        pos -= 60.0
    end
    # Devuelve la clase con los carros iniciales y el tiempo en 0.0
    return SimulacionTrafico(carros, 0.0, Float64[], Float64[])
end

# --- EJECUCIÓN Y ANIMACIÓN ---
println("Iniciando simulación...")
sim_local = iniciar_simulacion()
frames = 500
grid_x = range(0.0, VIA_LON, length=200) # 200 puntos para colorear
gradiente =	 cgrad([:red, :yellow, :green]) # Rojo (lento) > Verde (rápido)

# Loop animación por cada frame
anim = @animate for frame in 1:frames
    paso_simulacion!(sim_local)
    n_carros = length(sim_local.carros) # Número de carros
    x_carros = [c.posicion for c in sim_local.carros] # Posición x carros
    vels = [c.velocidad for c in sim_local.carros] # Velocidad carros
       
    # Margen para evitar superposiciones (Para interpolations)
    raw_pos = vcat(-0.1, x_carros, VIA_LON + 0.1)
    raw_vel = vcat(vels[1], vels, 25.0)		

    # Ordenar posiciones (Para interpolations)
    idx = sortperm(raw_pos) # Da los indices del menor al mayor
    sorted_pos = raw_pos[idx] # Ordena posiciones según idx
    sorted_vel = raw_vel[idx] # Ordena velocidades según idx

    # Crear interpolación lineal y aplicarla a la grilla de visualización
    itp = linear_interpolation(sorted_pos, sorted_vel)
    grid_v = itp(grid_x) # Grilla de velocidades dado punto x

	# Vuelve el vector -> matriz 200x1 (heatmap() solo acepta matrices)
	heatmap_mat = reshape(grid_v, 1, :)
    
    # Dibujar el fondo (Mapa de calor de velocidades)
    via = heatmap(grid_x, [5.0], heatmap_mat, c=gradiente, clims=(0,25), 
                  ylim=(0,10), xlim=(0,800), legend=true, framestyle=:box,
        		  axis=nothing, grid=false, size=(800,250)
    			 )
    
    # Dibujar los carros como puntos negros
    scatter!(via, x_carros, fill(5.0, n_carros), color=:black, markersize=6,
    		 label="")	
    
    title!(via, @sprintf("T: %.1fs", sim_local.tiempo,))
end

nombre_archivo = "SimulaciónTráfico.gif"
gif(anim, nombre_archivo, fps=5)
println("¡Listo! Archivo: $nombre_archivo")

# --- INFORME ---
# Se calculan la media de velocidades antes del segundo 5.0
indices_pre = findall(t -> t < T_FRENO_INICIO, sim_local.historial_t)
vel_base = isempty(indices_pre) ?
	   25.0 : mean(sim_local.historial_vel[indices_pre])

# Calcular el momento con la velocidad más baja
indices	ices_post = findall(t -> t >= T_FRENO_INICIO, sim_local.historial_t)
vels_post = sim_local.historial_vel[indices_post]
tiempos_post = sim_local.historial_t[indices_post]

vel_minima, idx_min = findmin(vels_post)
tiempo_peor = tiempos_post[idx_min]

# Calcular duración de la ola (Recuperación)
# Se recupera cuando la velocidad vuelve al 90% de lo normal
umbral = vel_base * 0.9
# Buscamos cuándo se recupera DESPUÉS del punto mínimo
indices_recup = findall(v -> v > umbral, vels_post[idx_min:end])
duracion_ola = 0.0
msg_recup = "No se recuperó en el tiempo simulado"
if !isempty(indices_recup)
   # El tiempo real es el tiempo del minimo + lo que tardó en subir
   idx_final = idx_min + indices_recup[1] - 1 # -1 Para compensar índice
   tiempo_final = tiempos_post[idx_final] 
   duracion_ola = tiempo_final - T_FRENO_INICIO
   msg_recup = @sprintf("%.1f segundos", duracion_ola)
end

	# @sprintf para no imprimir todos los decimales en memoria sino solo %.nf 
println("\n" * "="^40)
println("      INFORME DE TRÁFICO")
println("="^40)
println(@sprintf("Velocidad Normal:      %.2f m/s", vel_base))
println(@sprintf("Velocidad Mínima:      %.2f m/s (en t=%.1fs)",
	vel_minima, tiempo_peor))
println(@sprintf("Caída de velocidad:  %.1f %%",
	(1 - vel_minima/vel_base)*100))
println("-"^40)
println("Duración de la Ola de Choque: $msg_recup")
println("="^40)
