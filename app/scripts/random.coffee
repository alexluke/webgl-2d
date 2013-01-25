define ->
    class Random
        @next: ->
            return Math.random()

        @nextInt: (range) ->
            return Math.floor Math.random() * range
