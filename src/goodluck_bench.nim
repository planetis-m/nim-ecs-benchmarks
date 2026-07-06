import times, math, tables
import project2d/[entities, heaparrays, slottables]

include "benchmarks.nim"

const SAMPLE = 1000
const WARMUP = 1
const ENTITY_COUNT = 10000

type
  Position = object
    x, y: float32

  Velocity = object
    x, y: float32

  Acceleration = object
    x, y: float32

  Tag = object

  Health = object
    hp: int

  HasComponent = enum
    HasPosition,
    HasVelocity

  World = object
    signature: SlotTable[set[HasComponent]]
    position: Array[Position]
    velocity: Array[Velocity]

proc initWorld(): World =
  World(
    signature: initSlotTableOfCap[set[HasComponent]](ENTITY_COUNT),
    position: initArray[Position](),
    velocity: initArray[Velocity]()
  )

proc createEntity(world: var World): Entity =
  result = world.signature.incl({})

proc addPosition(world: var World, entity: Entity, position: Position) {.inline.} =
  world.position.valueAt(entity.idx) = position
  world.signature.valueAtSlot(entity.idx).incl HasPosition

proc addVelocity(world: var World, entity: Entity, velocity: Velocity) {.inline.} =
  world.velocity.valueAt(entity.idx) = velocity
  world.signature.valueAtSlot(entity.idx).incl HasVelocity

proc removeVelocity(world: var World, entity: Entity) {.inline.} =
  world.signature.valueAtSlot(entity.idx).excl HasVelocity

proc removeEntity(world: var World, entity: Entity) {.inline.} =
  world.signature.del(entity)

proc runGoodluckBenchmarks() =
  var suite = initSuite("Goodluck")

  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
    ),
    (
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
    )
  )
  showDetailed(suite.benchmarks[0])

  suite.add benchmarkWithSetup(
    "delete entity",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        world.removeEntity(entity)
    )
  )
  showDetailed(suite.benchmarks[1])

  suite.add benchmarkWithSetup(
    "add component",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
    )
  )
  showDetailed(suite.benchmarks[2])

  suite.add benchmarkWithSetup(
    "remove component",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        world.removeVelocity(entity)
    )
  )
  showDetailed(suite.benchmarks[3])

  suite.add benchmarkWithSetup(
    "add remove component",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
      for entity in ents:
        world.removeVelocity(entity)
    )
  )
  showDetailed(suite.benchmarks[4])

  suite.add benchmarkWithSetup(
    "iteration",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        world.addVelocity(entity, Velocity(x: 1.0, y: 1.0))
    ),
    (
      for entry in world.signature.pairs:
        if HasPosition in entry.value and HasVelocity in entry.value:
          let entity = entry.e
          world.position.valueAt(entity.idx).x += world.velocity.valueAt(entity.idx).x
          world.position.valueAt(entity.idx).y += world.velocity.valueAt(entity.idx).y
    )
  )
  showDetailed(suite.benchmarks[5])

  var s = 0'f32
  suite.add benchmarkWithSetup(
    "read",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        s += world.position.valueAt(entity.idx).x
    )
  )
  showDetailed(suite.benchmarks[6])

  suite.add benchmarkWithSetup(
    "write",
    SAMPLE,
    WARMUP,
    (
      var world = initWorld()
      var ents = newSeqOfCap[Entity](ENTITY_COUNT)
      for i in 0..<ENTITY_COUNT:
        let entity = world.createEntity()
        world.addPosition(entity, Position(x: 1.0, y: 1.0))
        ents.add entity
    ),
    (
      for entity in ents:
        world.position.valueAt(entity.idx).x = s
        world.position.valueAt(entity.idx).y = s
    )
  )
  showDetailed(suite.benchmarks[7])

  suite.showSummary()
  suite.saveSummary("goodluck")

if isMainModule:
  runGoodluckBenchmarks()
