import {Range} from "./range"
import * as p from "core/properties"
import {all, sum} from "core/util/array"
import {isArray, isNumber, isString} from "core/util/types"

_map_one = (factors) ->
  mapping = {}

  for f, i in factors
    if f == null
      throw new Error("")
    if f of mapping
      throw new Error("")
    mapping[f] = {value: 0.5 + i}

  return mapping

_map_two = (factors) ->
  tmp = {}
  mapping = {}

  for [f0, f1], i in factors
    if f0 == null
      throw new Error("")

    if f0 not of tmp
      tmp[f0] = []
    tmp[f0].push(0.5 + i)

  for [f0, f1], i in factors
    if f0 not of mapping
      avg = sum(tmp[f0]) / tmp[f0].length
      mapping[f0] = {value: avg, mapping: {}}

    if f1 of mapping[f0].mapping
      throw new Error("")

    if f1 != null
      mapping[f0].mapping[f1] = {value: 0.5 + i}

  return mapping

export class FactorRange extends Range
  type: 'FactorRange'

  @define {
    factors: [ p.Array,  [] ]
    start:   [ p.Number     ]
    end:     [ p.Number     ]
  }

  @getters {
    min: () -> @start
    max: () -> @end
  }

  initialize: (attrs, options) ->
    super(attrs, options)
    @_init()
    @connect(@properties.factors.change, () -> @_init())

  reset: () ->
    @_init()
    @change.emit()

  # convert a string factor into a synthetic coordinate
  synthetic: (x) ->
    if isNumber(x)
      return x

    if isString(x)
      return @_lookup([x])

    offset = 0
    if isNumber(x[x.length-1])
      offset = x[x.length-1]
      x = x.slice(0,-1)

    return @_lookup(x) + offset

  # convert an array of string factors into synthetic coordinates
  v_synthetic: (xs) ->
    result = (@synthetic(x) for x in xs)

  _init: () ->
    start = 0
    end = @factors.length
    @setv({start: start, end: end}, {silent: true})

    if all(@factors, isString)
      @_mapping = _map_one(@factors)

    else if all(@factors, (x) -> isArray(x) and x.length==2)
      @_mapping = _map_two(@factors)

    else
      throw new Error("")

  _lookup: (x) ->
    if x.length == 1
      return @_mapping[x[0]].value

    else
      return @_mapping[x[0]].mapping[x[1]].value
