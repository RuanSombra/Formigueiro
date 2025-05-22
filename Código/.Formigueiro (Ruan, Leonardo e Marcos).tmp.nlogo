patches-own [
  chemical             ;; amount of chemical on this patch
  food                 ;; amount of food on this patch (0, 1, or 2)
  nest?                ;; true on nest patches, false elsewhere
  nest-scent           ;; number that is higher closer to the nest
  food-source-number   ;; number (1, 2, or 3) to identify the food sources
  obstacle?            ;; true se o patch for um obstáculo (pedra), false caso contrário
  solo-type            ;; tipo do solo (0=normal, 1=areia, 2=lama, 3=fertilizado)
  dificuldade-solo     ;; valor que representa a dificuldade de atravessar este solo
]

turtles-own [
  energy               ;; energia da formiga/predador
  carrying-food?       ;; está carregando comida?
  ant-type            ;; tipo da formiga: "queen", "worker", "ninja", "tank", "mirmecobio"
  patrol-angle        ;; ângulo para patrulha dos tanks
  target-enemy        ;; inimigo sendo perseguido (para ninjas)
  food-delivered      ;; quantidade de comida entregue (para rainha)
  hunt-cooldown       ;; tempo de recarga entre ataques do mirmecóbio
  fleeing?            ;; se está fugindo após ser atacado
  flee-timer          ;; contador para tempo de fuga
  last-damage-tick    ;; último tick em que recebeu dano (para evitar spam de ataques)
]

globals [
  energy-inicial      ;; energia inicial das formigas
  energia-ganho       ;; energia ganha ao entregar comida
  energia-perda       ;; energia perdida ao se movimentar
  queen-food-count    ;; contador de comida da rainha
  reproduction-threshold ;; limite para reprodução
  patrol-radius       ;; raio de patrulha dos tanks
  mirmecobio-spawn-rate ;; taxa de aparição de mirmecóbios
  mirmecobio-count    ;; contador de mirmecóbios ativos
;  population          ;; população inicial (variável necessária)
;  num-obstacles       ;; número de obstáculos
;  num-areia           ;; número de patches de areia
;  num-lama            ;; número de patches de lama
;  num-fertilizado     ;; número de patches fertilizados
;  show-energy?        ;; mostrar energia das formigas
;  diffusion-rate      ;; taxa de difusão química
;  evaporation-rate    ;; taxa de evaporação química
  total-food-collected ;; contador total de comida coletada
  game-over?          ;; flag para indicar fim de jogo
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  ;; Definir valores padrão se não definidos pela interface
  if population = 0 [ set population 20 ]
  if num-obstacles = 0 [ set num-obstacles 5 ]
  if num-areia = 0 [ set num-areia 3 ]
  if num-lama = 0 [ set num-lama 3 ]
  if num-fertilizado = 0 [ set num-fertilizado 2 ]
  if diffusion-rate = 0 [ set diffusion-rate 50 ]
  if evaporation-rate = 0 [ set evaporation-rate 10 ]

  ;; Definir valores de energia e reprodução
  set energy-inicial 1000
  set energia-ganho 15
  set energia-perda 1
  set show-energy? false
  set queen-food-count 0
  set reproduction-threshold 50  ;; Rainha precisa de 50 unidades de comida para reproduzir
  set patrol-radius 8
  set mirmecobio-spawn-rate 0.1  ;; 0.1% de chance por tick de aparecer um mirmecóbio
  set mirmecobio-count 0
  set total-food-collected 0
  set game-over? false

  set-default-shape turtles "bug"

  ;; Criar a rainha primeiro
  create-turtles 1 [
    set ant-type "queen"
    set size 3
    set color pink
    set energy energy-inicial * 2  ;; Rainha tem mais energia
    set carrying-food? false
    set food-delivered 0
    set hunt-cooldown 0
    set fleeing? false
    set flee-timer 0
    set last-damage-tick 0
    set target-enemy nobody
    set patrol-angle 0
    ;; Posicionar a rainha no centro do ninho
    setxy 0 0
  ]

  ;; Criar população inicial de operárias
  create-turtles (population - 1) [
    set ant-type "worker"
    set size 2
    set color red
    set energy energy-inicial
    set carrying-food? false
    set food-delivered 0
    set hunt-cooldown 0
    set fleeing? false
    set flee-timer 0
    set last-damage-tick 0
    set target-enemy nobody
    set patrol-angle 0
    ;; Posicionar perto do ninho
    setxy (random 10 - 5) (random 10 - 5)
  ]

  setup-patches
  setup-obstacles
  setup-solos
  reset-ticks
end

to setup-patches
  ask patches [
    setup-nest
    setup-food
    set obstacle? false
    set solo-type 0
    set dificuldade-solo 1
    set chemical 0
    recolor-patch
  ]
end

to setup-nest  ;; patch procedure
  set nest? (distancexy 0 0) < 5
  set nest-scent 200 - distancexy 0 0
end

to setup-food  ;; patch procedure
  ;; inicializar food-source-number como 0
  set food-source-number 0
  set food 0

  ;; setup food source one on the right
  if (distancexy (0.6 * max-pxcor) 0) < 5
  [ set food-source-number 1 ]
  ;; setup food source two on the lower-left
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5
  [ set food-source-number 2 ]
  ;; setup food source three on the upper-left
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5
  [ set food-source-number 3 ]
  ;; set "food" at sources to either 1 or 2, randomly
  if food-source-number > 0
  [ set food one-of [1 2] ]
end

to setup-solos
  create-solo-patches num-areia 1 2 yellow
  create-solo-patches num-lama 2 3 (brown - 2)
  create-solo-patches num-fertilizado 3 0.5 lime
end

to create-solo-patches [num tipo dificuldade cor-solo]
  let current-patches 0
  let attempts 0  ;; Contador para evitar loop infinito
  while [current-patches < num and attempts < 200] [
    let potential-patch one-of patches
    ask potential-patch [
      if (not nest?) and (food-source-number = 0) and (not obstacle?) and (solo-type = 0) [
        ask patches in-radius (2 + random 3) [
          if (not nest?) and (food-source-number = 0) and (not obstacle?) and (solo-type = 0) [
            set solo-type tipo
            set dificuldade-solo dificuldade
            recolor-patch
          ]
        ]
        set current-patches current-patches + 1
      ]
    ]
    set attempts attempts + 1
  ]
end

to setup-obstacles
  let current-obstacles 0
  let attempts 0  ;; Contador para evitar loop infinito
  while [current-obstacles < num-obstacles and attempts < 100] [
    let potential-patch one-of patches
    ask potential-patch [
      if (not nest?) and (food-source-number = 0) and (not obstacle?) [
        ask patches in-radius (1 + random 3) [
          if (not nest?) and (food-source-number = 0) and (not obstacle?) [
            set obstacle? true
            recolor-patch
          ]
        ]
        set current-obstacles current-obstacles + 1
      ]
    ]
    set attempts attempts + 1
  ]
end

to recolor-patch  ;; patch procedure
  ifelse nest?
  [ set pcolor violet ]
  [ ifelse obstacle?
    [ set pcolor gray - 2 ]
    [ ifelse food > 0
      [ if food-source-number = 1 [ set pcolor cyan ]
        if food-source-number = 2 [ set pcolor sky  ]
        if food-source-number = 3 [ set pcolor blue ] ]
      [ ifelse solo-type > 0
        [ if solo-type = 1 [ set pcolor yellow ]
          if solo-type = 2 [ set pcolor brown - 2 ]
          if solo-type = 3 [ set pcolor lime ]
        ]
        [ set pcolor scale-color green chemical 0.1 5 ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go
  if game-over? [ stop ]

  ;; Verificar se ainda há formigas vivas
  if not any? turtles with [ant-type != "mirmecobio"] [
    set game-over? true
    user-message "Todas as formigas morreram! Fim de jogo."
    stop
  ]

  ;; Chance de aparecer um mirmecóbio
  if random-float 100 < mirmecobio-spawn-rate and mirmecobio-count < 3 [
    spawn-mirmecobio
  ]

  ask turtles [
    ;; Comportamento específico por tipo de formiga/predador
    if ant-type = "queen" [ queen-behavior ]
    if ant-type = "worker" [ worker-behavior ]
    if ant-type = "ninja" [ ninja-behavior ]
    if ant-type = "tank" [ tank-behavior ]
    if ant-type = "mirmecobio" [ mirmecobio-behavior ]

    ;; Consumo de energia (varia por tipo)
    consume-energy
  ]

  check-death
  display-energy
  diffuse-chemicals
  replenish-food  ;; Adicionar reposição gradual de comida
  tick
end

;; Comportamento da Rainha
to queen-behavior
  ;; A rainha fica no ninho esperando comida
  if not nest? [
    ;; Se não estiver no ninho, volta para lá
    uphill-nest-scent
    move-if-possible
  ]

  ;; Verifica se pode reproduzir
  if queen-food-count >= reproduction-threshold [
    reproduce-ants
    set queen-food-count queen-food-count - reproduction-threshold
  ]

  ;; A rainha se move muito pouco, apenas ajusta posição no ninho
  if nest? and random 20 = 0 [  ;; Reduzido movimento da rainha
    rt random 60 - 30
    if can-move? 1 and patch-ahead 1 != nobody and [nest?] of patch-ahead 1 [
      fd 1
    ]
  ]
end

;; Comportamento da Operária (similar ao original)
to worker-behavior
  ifelse carrying-food?
  [ return-to-nest ]
  [ look-for-food ]

  wiggle
  move-if-possible
  deposit-chemical
end

;; Procedimento para criar mirmecóbio
to spawn-mirmecobio
  ;; Criar mirmecóbio em uma borda aleatória do mundo
  let spawn-x 0
  let spawn-y 0

  let edge random 4
  if edge = 0 [ ;; borda superior
    set spawn-x random-float (2 * max-pxcor) - max-pxcor
    set spawn-y max-pycor - 2
  ]
  if edge = 1 [ ;; borda direita
    set spawn-x max-pxcor - 2
    set spawn-y random-float (2 * max-pycor) - max-pycor
  ]
  if edge = 2 [ ;; borda inferior
    set spawn-x random-float (2 * max-pxcor) - max-pxcor
    set spawn-y min-pycor + 2
  ]
  if edge = 3 [ ;; borda esquerda
    set spawn-x min-pxcor + 2
    set spawn-y random-float (2 * max-pycor) - max-pycor
  ]

  create-turtles 1 [
    set ant-type "mirmecobio"
    set shape "mirmecóbio"  ;; Usar forma de pessoa para representar o predador
    set size 10
    set color brown
    set energy 2000  ;; Mirmecóbio tem muita energia
    set carrying-food? false
    set hunt-cooldown 0
    set fleeing? false
    set flee-timer 0
    set last-damage-tick 0
    set target-enemy nobody
    set food-delivered 0
    set patrol-angle 0
    setxy spawn-x spawn-y
  ]

  set mirmecobio-count mirmecobio-count + 1
end

;; Comportamento do Mirmecóbio
to mirmecobio-behavior
  ;; Reduzir cooldown
  if hunt-cooldown > 0 [ set hunt-cooldown hunt-cooldown - 1 ]
  if flee-timer > 0 [ set flee-timer flee-timer - 1 ]

  ;; Se está fugindo, continua na direção oposta às formigas
  if fleeing? [
    if flee-timer <= 0 [
      set fleeing? false
      set color brown  ;; Volta à cor normal
    ]

    ;; Foge das formigas defensoras
    let defenders turtles in-radius 10 with [ant-type = "ninja" or ant-type = "tank"]
    if any? defenders [
      let nearest-defender min-one-of defenders [distance myself]
      face nearest-defender
      rt 180  ;; Vira na direção oposta
    ]

    move-predator
    stop
  ]

  ;; Procurar formigas próximas para caçar
  let nearby-ants turtles in-radius 8 with [ant-type != "mirmecobio"]

  if any? nearby-ants [
    ;; Priorizar operárias, depois ninjas, depois tanks, rainha por último
    let target nobody

    let workers nearby-ants with [ant-type = "worker"]
    let ninjas nearby-ants with [ant-type = "ninja"]
    let tanks nearby-ants with [ant-type = "tank"]
    let queens nearby-ants with [ant-type = "queen"]

    if any? workers [ set target one-of workers ]
    if target = nobody and any? ninjas [ set target one-of ninjas ]
    if target = nobody and any? tanks [ set target one-of tanks ]
    if target = nobody and any? queens [ set target one-of queens ]

    if target != nobody [
      set target-enemy target
      face target-enemy

      ;; Atacar se estiver próximo o suficiente e sem cooldown
      if distance target-enemy <= 2 and hunt-cooldown = 0 [
        attack-ant target-enemy
        set hunt-cooldown 20  ;; Cooldown de 20 ticks entre ataques
      ]
    ]
  ]

  ;; Se tem um alvo, persegue
  if target-enemy != nobody [
    if is-turtle? target-enemy [ ;; Verifica se o alvo ainda existe
      face target-enemy
      move-predator
      if distance target-enemy > 15 [
        set target-enemy nobody  ;; Desiste se muito longe
      ]
    ]
    if not is-turtle? target-enemy [
      set target-enemy nobody
    ]
  ]

  ;; Se não tem alvo, move-se em direção ao ninho
  if target-enemy = nobody [
    facexy 0 0
    move-predator
  ]

  ;; Verificar se está sendo atacado por defensores
  let attackers turtles in-radius 3 with [ant-type = "ninja" or ant-type = "tank"]
  if any? attackers and random 10 < 3 and (ticks - last-damage-tick) > 5 [  ;; 30% chance de fugir quando atacado
    set fleeing? true
    set flee-timer 50  ;; Foge por 50 ticks
    set color brown + 2  ;; Muda cor para indicar que está fugindo
    set energy energy - 100  ;; Perde energia quando atacado
    set last-damage-tick ticks
  ]
end

;; Movimento do predador
to move-predator
  let p patch-ahead 1
  ifelse p = nobody or [obstacle?] of p
  [
    rt random 90 - 45
  ]
  [
    ;; Mirmecóbio move mais devagar em alguns tipos de solo
    let dificuldade [dificuldade-solo] of patch-here
    if random-float 1.0 > (dificuldade - 0.5) / dificuldade [
      fd 1
    ]
  ]
end

;; Ataque do mirmecóbio
to attack-ant [victim]
  if victim != nobody and is-turtle? victim [
    ask victim [
      ;; Evitar spam de ataques
      if (ticks - last-damage-tick) > 3 [
        ;; Formiga perde muita energia quando atacada
        set energy energy - 200
        set last-damage-tick ticks

        ;; Efeito visual do ataque
        set color white

        ;; Se for operária carregando comida, perde a comida
        if ant-type = "worker" and carrying-food? [
          set carrying-food? false
          set color red
          ;; A comida volta para o patch
          ask patch-here [
            if food-source-number > 0 [
              set food food + 1
            ]
          ]
        ]
      ]
    ]

    ;; Mirmecóbio ganha energia ao atacar
    set energy energy + 50
  ]
end

;; Comportamento do Ninja
to ninja-behavior
  ;; Procurar predadores próximos
  let nearby-predators turtles in-radius 15 with [ant-type = "mirmecobio"]

  if any? nearby-predators [
    ;; Perseguir o predador mais próximo
    let closest-predator min-one-of nearby-predators [distance myself]
    set target-enemy closest-predator
    face target-enemy

    ;; Atacar se próximo
    if distance target-enemy <= 2 [
      attack-predator target-enemy
    ]
  ]

  ;; Se não tem alvo, patrulha aleatoriamente ou ajuda operárias
  if target-enemy = nobody or not is-turtle? target-enemy [
    ;; Ocasionalmente ajuda operárias em perigo
    let workers-in-danger turtles in-radius 10 with [ant-type = "worker" and energy < 300]
    if any? workers-in-danger and random 5 = 0 [
      let worker-to-help one-of workers-in-danger
      face worker-to-help
    ]
    if not any? workers-in-danger [
      ;; Movimento mais rápido e errático
      rt random 90 - 45
      if random 3 = 0 [ rt 180 ]  ;; Mudança brusca de direção ocasional
    ]
    set target-enemy nobody
  ]

  wiggle
  move-if-possible
end

;; Comportamento do Tank
to tank-behavior
  ;; Verificar se há mirmecóbios próximos para defender
  let nearby-predators turtles in-radius 10 with [ant-type = "mirmecobio"]

  if any? nearby-predators [
    ;; Posicionar-se entre o predador e o ninho
    let closest-predator min-one-of nearby-predators [distance myself]

    ;; Calcular posição defensiva entre predador e ninho
    let predator-x [xcor] of closest-predator
    let predator-y [ycor] of closest-predator
    let defend-x (predator-x + 0) / 2  ;; Ponto médio entre predador e ninho (0,0)
    let defend-y (predator-y + 0) / 2

    facexy defend-x defend-y

    ;; Atacar se o predador estiver muito próximo
    if distance closest-predator <= 3 [
      face closest-predator
      attack-predator closest-predator
    ]

    move-if-possible
  ]

  ;; Se não há predadores, fazer patrulha normal ao redor do ninho
  if not any? nearby-predators [
    ;; Se está muito longe do ninho, volta
    if distancexy 0 0 > patrol-radius * 1.5 [
      facexy 0 0
      move-if-possible
      stop
    ]

    ;; Se está muito perto do ninho, se afasta um pouco
    if distancexy 0 0 < patrol-radius * 0.5 [
      rt 180
      move-if-possible
      stop
    ]

    ;; Patrulha circular
    set patrol-angle patrol-angle + 15
    if patrol-angle >= 360 [ set patrol-angle 0 ]

    let target-x patrol-radius * cos(patrol-angle)
    let target-y patrol-radius * sin(patrol-angle)

    facexy target-x target-y
    move-if-possible
  ]
end

;; Ataque de ninjas e tanks contra predadores
to attack-predator [predator]
  if predator != nobody and is-turtle? predator [
    ask predator [
      ;; Evitar spam de ataques
      if (ticks - last-damage-tick) > 3 [
        ;; Predador perde energia quando atacado
        let damage 50
        if [ant-type] of myself = "tank" [ set damage 75 ]  ;; Tanks causam mais dano

        set energy energy - damage
        set last-damage-tick ticks

        ;; Chance de fazer o predador fugir
        if random 10 < 4 [  ;; 40% chance
          set fleeing? true
          set flee-timer 30
          set color brown + 2
        ]
      ]
    ]

    ;; Formiga atacante também perde um pouco de energia
    set energy energy - 10
  ]
end

;; Procedimento para reprodução da rainha
to reproduce-ants
  let num-new-ants random 5 + 2  ;; Entre 2 e 6 novas formigas

  repeat num-new-ants [
    ;; Determina o tipo da nova formiga aleatoriamente
    let new-type "worker"  ;; padrão
    let rand-num random 100

    if rand-num < 60 [ set new-type "worker" ]    ;; 60% operárias
    if rand-num >= 60 and rand-num < 80 [ set new-type "ninja" ]  ;; 20% ninjas
    if rand-num >= 80 [ set new-type "tank" ]     ;; 20% tanks

    ;; Criar nova formiga perto da rainha
    hatch 1 [
      set ant-type new-type
      set carrying-food? false
      set food-delivered 0
      set energy energy-inicial
      set hunt-cooldown 0
      set fleeing? false
      set flee-timer 0
      set last-damage-tick 0
      set target-enemy nobody

      ;; Configurar aparência por tipo
      if ant-type = "worker" [
        set color red
        set size 2
      ]
      if ant-type = "ninja" [
        set color black
        set size 1.5
      ]
      if ant-type = "tank" [
        set color blue
        set size 2.5
        set patrol-angle random 360
      ]

      ;; Posicionar perto do ninho
      setxy (random 6 - 3) (random 6 - 3)
    ]
  ]
end

;; Modificação do procedimento de retorno ao ninho para alimentar a rainha
to return-to-nest
  ifelse nest?
  [
    if carrying-food? [
      ;; Entregar comida para a rainha
      set carrying-food? false
      set color red
      set energy energy + energia-ganho

      ;; Aumentar contador de comida da rainha
      set queen-food-count queen-food-count + 1
      set total-food-collected total-food-collected + 1
    ]
    rt 180
  ]
  [
    uphill-nest-scent
  ]
end

to look-for-food
  if food > 0 [
    set color orange + 1
    set food food - 1
    set carrying-food? true
    rt 180
    stop
  ]

  if (chemical >= 0.05) and (chemical < 2)
  [ uphill-chemical ]
end

;; Procedimento auxiliar para movimento
to move-if-possible
  let p patch-ahead 1
  ifelse p = nobody or [obstacle?] of p
  [
    rt random 180  ;; Mudança para evitar ficar preso
  ]
  [
    let dificuldade [dificuldade-solo] of patch-here
    if random-float 1.0 > (dificuldade - 1) / dificuldade [
      fd 1
    ]
  ]
end

;; Consumo de energia por tipo
to consume-energy
  let base-consumption energia-perda

  if ant-type = "queen" [ set base-consumption energia-perda * 0.5 ]        ;; Rainha consome menos
  if ant-type = "worker" [ set base-consumption energia-perda ]             ;; Consumo normal
  if ant-type = "ninja" [ set base-consumption energia-perda * 1.5 ]        ;; Ninja consome mais
  if ant-type = "tank" [ set base-consumption energia-perda * 1.2 ]         ;; Tank consome um pouco mais
  if ant-type = "mirmecobio" [ set base-consumption energia-perda * 2 ]     ;; Mirmecóbio consome mais

  let dificuldade [dificuldade-solo] of patch-here
  set energy energy - (base-consumption * dificuldade)
end

to deposit-chemical
  let solo-atual [solo-type] of patch-here
  let chemical-amount 60

  if solo-atual = 2 [ set chemical-amount 80 ]
  if solo-atual = 3 [ set chemical-amount 40 ]

  ;; Apenas operárias depositam químico quando retornam com comida
  if ant-type = "worker" and carrying-food? [
    ask patch-here [
      set chemical chemical + chemical-amount
    ]
  ]
end

to diffuse-chemicals
  diffuse chemical (diffusion-rate / 100)
  ask patches [
    let taxa-evaporacao evaporation-rate
    if solo-type = 3 [
      set taxa-evaporacao evaporation-rate * 0.7
    ]
    set chemical chemical * (100 - taxa-evaporacao) / 100
    recolor-patch
  ]
end

;; Novo procedimento para reposição gradual de comida
to replenish-food
  if random 100 < 2 [  ;; 2% de chance por tick
    ask patches with [food-source-number > 0 and food < 2] [
      if random 10 < 3 [  ;; 30% de chance para cada fonte
        set food food + 1
        recolor-patch
      ]
    ]
  ]
end

to check-death
  ask turtles [
    if energy <= 0 [
      ;; Se a rainha morrer, o jogo acaba
      if ant-type = "queen" [
        set game-over? true
        user-message "A Rainha morreu! A colônia não pode continuar."
        stop
      ]

      ;; Se um mirmecóbio morrer, diminui o contador
      if ant-type = "mirmecobio" [
        set mirmecobio-count mirmecobio-count - 1
      ]

      die
    ]
  ]
end

to uphill-nest-scent
  let scent-ahead nest-scent-at-angle   0
  let scent-right nest-scent-at-angle  45
  let scent-left  nest-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

to uphill-chemical
  let scent-ahead chemical-scent-at-angle   0
  let scent-right chemical-scent-at-angle  45
  let scent-left  chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

to wiggle
  rt random 40
  lt random 40
  if not can-move? 1 [
    rt 180
  ]
end

to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  if [obstacle?] of p [ report 0 ]
  report [nest-scent] of p
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  if [obstacle?] of p [ report 0 ]
  report [chemical] of p
end

to display-energy
  ifelse show-energy?
  [
    ask turtles [
      set label energy
    ]
  ]
  [
    ask turtles [
      set label ""
    ]
  ]
end

to update-obstacles
  ask patches [
    if obstacle? [
      set obstacle? false
      recolor-patch
    ]
  ]
  setup-obstacles
end

to update-solos
  ask patches [
    if solo-type > 0 [
      set solo-type 0
      set dificuldade-solo 1
      recolor-patch
    ]
  ]
  setup-solos
end

;; Novos procedimentos adicionais para melhorar a simulação

;; Procedimento para resetar a simulação mantendo configurações
to reset-simulation
  ask turtles [ die ]
  ask patches [
    set chemical 0
    if food-source-number > 0 [
      set food one-of [1 2]
    ]
    recolor-patch
  ]
  set queen-food-count 0
  set mirmecobio-count 0
  set total-food-collected 0
  set game-over? false

  ;; Recriar formigas
  create-turtles 1 [
    set ant-type "queen"
    set size 3
    set color pink
    set energy energy-inicial * 2
    set carrying-food? false
    set food-delivered 0
    set hunt-cooldown 0
    set fleeing? false
    set flee-timer 0
    set last-damage-tick 0
    set target-enemy nobody
    set patrol-angle 0
    setxy 0 0
  ]

  create-turtles (population - 1) [
    set ant-type "worker"
    set size 2
    set color red
    set energy energy-inicial
    set carrying-food? false
    set food-delivered 0
    set hunt-cooldown 0
    set fleeing? false
    set flee-timer 0
    set last-damage-tick 0
    set target-enemy nobody
    set patrol-angle 0
    setxy (random 10 - 5) (random 10 - 5)
  ]

  reset-ticks
end

;; Procedimento para adicionar comida manualmente
to add-food-source
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not nest? and not obstacle? [
        set food-source-number 4  ;; Fonte de comida temporária
        set food 5  ;; Mais comida que as fontes normais
        recolor-patch
      ]
    ]
  ]
end

;; Procedimento para mostrar estatísticas
to show-stats
  print (word "=== ESTATÍSTICAS DA COLÔNIA ===")
  print (word "Tempo decorrido: " ticks " ticks")
  print (word "Formigas vivas: " count turtles with [ant-type != "mirmecobio"])
  print (word "  - Operárias: " count turtles with [ant-type = "worker"])
  print (word "  - Ninjas: " count turtles with [ant-type = "ninja"])
  print (word "  - Tanks: " count turtles with [ant-type = "tank"])
  print (word "  - Rainha: " count turtles with [ant-type = "queen"])
  print (word "Mirmecóbios ativos: " mirmecobio-count)
  print (word "Comida coletada total: " total-food-collected)
  print (word "Comida da rainha: " queen-food-count)
  print (word "Reproduções possíveis: " floor(queen-food-count / reproduction-threshold))

  ;; Energia média por tipo
  if any? turtles with [ant-type = "worker"] [
    print (word "Energia média operárias: " precision (mean [energy] of turtles with [ant-type = "worker"]) 2)
  ]
  if any? turtles with [ant-type = "ninja"] [
    print (word "Energia média ninjas: " precision (mean [energy] of turtles with [ant-type = "ninja"]) 2)
  ]
  if any? turtles with [ant-type = "tank"] [
    print (word "Energia média tanks: " precision (mean [energy] of turtles with [ant-type = "tank"]) 2)
  ]
  if any? turtles with [ant-type = "queen"] [
    print (word "Energia da rainha: " [energy] of one-of turtles with [ant-type = "queen"])
  ]
  print "=================================="
end

;; Procedimento para modo de emergência (quando colônia está em perigo)
to emergency-mode
  ;; Aumentar taxa de reprodução temporariamente
  ask turtles with [ant-type = "queen"] [
    if queen-food-count >= (reproduction-threshold * 0.5) [
      reproduce-ants
      set queen-food-count queen-food-count - (reproduction-threshold * 0.5)
    ]
  ]

  ;; Aumentar agressividade dos defensores
  ask turtles with [ant-type = "ninja" or ant-type = "tank"] [
    set energy energy + 100  ;; Boost de energia
  ]

  ;; Aumentar eficiência das operárias
  ask turtles with [ant-type = "worker"] [
    set energia-ganho energia-ganho * 1.5
  ]
end

;; Procedimento para balancear a simulação automaticamente
to auto-balance
  let total-ants count turtles with [ant-type != "mirmecobio"]
  let total-predators mirmecobio-count

  ;; Se há muitos predadores comparado às formigas
  if total-predators > (total-ants / 5) [
    set mirmecobio-spawn-rate mirmecobio-spawn-rate * 0.8  ;; Reduz spawn de predadores
  ]

  ;; Se há poucas formigas
  if total-ants < 10 [
    emergency-mode
  ]

  ;; Se há muitas formigas, aumenta dificuldade
  if total-ants > 50 [
    set mirmecobio-spawn-rate mirmecobio-spawn-rate * 1.2
  ]
end

;; Reportar informações úteis para monitores
to-report worker-count
  report count turtles with [ant-type = "worker"]
end

to-report ninja-count
  report count turtles with [ant-type = "ninja"]
end

to-report tank-count
  report count turtles with [ant-type = "tank"]
end

to-report predator-count
  report mirmecobio-count
end

to-report queen-energy
  let queens turtles with [ant-type = "queen"]
  ifelse any? queens [
    report [energy] of one-of queens
  ] [
    report 0
  ]
end

to-report food-in-nest
  report queen-food-count
end

to-report average-worker-energy
  let workers turtles with [ant-type = "worker"]
  ifelse any? workers [
    report precision (mean [energy] of workers) 2
  ] [
    report 0
  ]
end

to-report chemical-intensity
  report precision (mean [chemical] of patches) 4
end

;; Procedimento para criar diferentes cenários de teste
to scenario-peaceful
  set mirmecobio-spawn-rate 0.05  ;; Menos predadores
  set reproduction-threshold 30   ;; Reprodução mais fácil
  set energia-ganho 20           ;; Mais energia por comida
end

to scenario-survival
  set mirmecobio-spawn-rate 0.2   ;; Mais predadores
  set reproduction-threshold 70   ;; Reprodução mais difícil
  set energia-ganho 10           ;; Menos energia por comida
end

to scenario-balanced
  set mirmecobio-spawn-rate 0.1
  set reproduction-threshold 50
  set energia-ganho 15
end
@#$#@#$#@
GRAPHICS-WINDOW
527
69
1032
575
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
293
246
373
279
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1251
70
1441
103
diffusion-rate
diffusion-rate
0.0
99.0
50.0
1.0
1
NIL
HORIZONTAL

SLIDER
1250
117
1440
150
evaporation-rate
evaporation-rate
0.0
99.0
10.0
1.0
1
NIL
HORIZONTAL

BUTTON
383
246
458
279
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
1048
71
1238
104
population
population
0.0
200.0
49.0
1.0
1
NIL
HORIZONTAL

PLOT
246
293
489
572
Food in each pile
time
food
0.0
50.0
0.0
120.0
true
false
"" ""
PENS
"food-in-pile1" 1.0 0 -11221820 true "" "plotxy ticks sum [food] of patches with [pcolor = cyan]"
"food-in-pile2" 1.0 0 -13791810 true "" "plotxy ticks sum [food] of patches with [pcolor = sky]"
"food-in-pile3" 1.0 0 -13345367 true "" "plotxy ticks sum [food] of patches with [pcolor = blue]"

SWITCH
314
204
448
237
show-energy?
show-energy?
1
1
-1000

SLIDER
1049
113
1221
146
num-areia
num-areia
0
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
1050
156
1222
189
num-lama
num-lama
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
1050
200
1222
233
num-fertilizado
num-fertilizado
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
1050
248
1222
281
num-obstacles
num-obstacles
0
20
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

In this project, a colony of ants forages for food. Though each ant follows a set of simple rules, the colony as a whole acts in a sophisticated way.

## HOW IT WORKS

When an ant finds a piece of food, it carries the food back to the nest, dropping a chemical as it moves. When other ants "sniff" the chemical, they follow the chemical toward the food. As more ants carry food to the nest, they reinforce the chemical trail.

## HOW TO USE IT

Click the SETUP button to set up the ant nest (in violet, at center) and three piles of food. Click the GO button to start the simulation. The chemical is shown in a green-to-white gradient.

The EVAPORATION-RATE slider controls the evaporation rate of the chemical. The DIFFUSION-RATE slider controls the diffusion rate of the chemical.

If you want to change the number of ants, move the POPULATION slider before pressing SETUP.

## THINGS TO NOTICE

The ant colony generally exploits the food source in order, starting with the food closest to the nest, and finishing with the food most distant from the nest. It is more difficult for the ants to form a stable trail to the more distant food, since the chemical trail has more time to evaporate and diffuse before being reinforced.

Once the colony finishes collecting the closest food, the chemical trail to that food naturally disappears, freeing up ants to help collect the other food sources. The more distant food sources require a larger "critical number" of ants to form a stable trail.

The consumption of the food is shown in a plot.  The line colors in the plot match the colors of the food piles.

## EXTENDING THE MODEL

Try different placements for the food sources. What happens if two food sources are equidistant from the nest? When that happens in the real world, ant colonies typically exploit one source then the other (not at the same time).

In this project, the ants use a "trick" to find their way back to the nest: they follow the "nest scent." Real ants use a variety of different approaches to find their way back to the nest. Try to implement some alternative strategies.

The ants only respond to chemical levels between 0.05 and 2.  The lower limit is used so the ants aren't infinitely sensitive.  Try removing the upper limit.  What happens?  Why?

In the `uphill-chemical` procedure, the ant "follows the gradient" of the chemical. That is, it "sniffs" in three directions, then turns in the direction where the chemical is strongest. You might want to try variants of the `uphill-chemical` procedure, changing the number and placement of "ant sniffs."

## NETLOGO FEATURES

The built-in `diffuse` primitive lets us diffuse the chemical easily without complicated code.

The primitive `patch-right-and-ahead` is used to make the ants smell in different directions without actually turning.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Ants model.  http://ccl.northwestern.edu/netlogo/models/Ants.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 1998.

<!-- 1997 1998 MIT -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mirmecóbio
false
0
Polygon -7500403 false true 135 105
Polygon -7500403 false true 135 75 150 45 150 45 150 75 165 60 180 60 195 75 195 45 210 60 210 75 225 90 240 90 255 105 255 120 240 135 225 120 210 120 180 105 165 105 165 120 165 135 195 150 210 165 210 180 195 165 180 165 180 150 165 150 165 165 195 180 195 195 180 210 180 195 165 195 165 195 165 180 150 180 150 210 135 225 120 225 120 240 120 255 135 270 135 270 105 270 105 240 90 240 30 270 75 210 75 195 60 180 75 165 75 150 75 150 75 135 90 120 105 90 120 90 135 90 135 75
Circle -7500403 false true 180 105 0
Polygon -1 true false 75 210 135 195 75 195
Polygon -1 true false 60 180 135 165 75 165
Polygon -1 true false 75 150 135 135 75 135
Polygon -1 true false 90 120 120 105 105 105 90 105
Polygon -2674135 true false 165 90 165 75 195 90 165 90
Line -7500403 true 165 90 240 120
Polygon -7500403 true true 240 120 240 135 240 120 255 120
Polygon -16777216 true false 240 135 240 120 255 120
Polygon -16777216 true false 165 90 165 105 180 105 210 120 225 120 240 135

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
