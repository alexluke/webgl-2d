require [
    'webgl'
], (WebGL) ->
    canvas = document.getElementById 'canvas'
    try
        gl = new WebGL canvas
    catch e
        alert e
        return

    gl.draw()
