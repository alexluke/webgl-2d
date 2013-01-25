define [
    'random'
], (Random) ->
    class WebGL
        constructor: (canvas) ->
            if typeof canvas == 'string'
                canvas = document.getElementById canvas
            @gl = null

            try
                @gl = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')
            catch e

            if not @gl
                throw 'Cannot init WebGL'

            @width = canvas.width
            @height = canvas.height
            @image = document.getElementById 'image'

            @initShaders()

        _compileShader: (id) ->
            shaderScript = document.getElementById id
            if not shaderScript
                return null

            shader = switch shaderScript.type
                when 'x-shader/x-fragment'
                    @gl.createShader @gl.FRAGMENT_SHADER
                when 'x-shader/x-vertex'
                    @gl.createShader @gl.VERTEX_SHADER

            source = ''
            currentChild = shaderScript.firstChild

            while currentChild
                if currentChild.nodeType == currentChild.TEXT_NODE
                    source += currentChild.textContent
                currentChild = currentChild.nextSibling

            @gl.shaderSource shader, source
            @gl.compileShader shader

            if not @gl.getShaderParameter shader, @gl.COMPILE_STATUS
                throw "Cannot compile shader #{ id }: " + @gl.getShaderInfoLog shader

            return shader

        initShaders: ->
            vertexShader = @_compileShader '2d-vertex-shader'
            fragmentShader = @_compileShader '2d-fragment-shader'
            if not vertexShader or not fragmentShader
                throw "Missing shaders"

            program = @gl.createProgram()
            @gl.attachShader program, vertexShader
            @gl.attachShader program, fragmentShader
            @gl.linkProgram program

            if not @gl.getProgramParameter program, @gl.LINK_STATUS
                throw "Cannot link shader program: " + @gl.getShaderInfoLog program

            @shaderProgram = program
            @gl.useProgram @shaderProgram

        draw: ->
            positionLocation = @gl.getAttribLocation @shaderProgram, 'a_position'
            texCoordLocation = @gl.getAttribLocation @shaderProgram, 'a_texCoord'
            resolutionLocation = @gl.getUniformLocation @shaderProgram, 'u_resolution'
            @gl.uniform2f resolutionLocation, @width, @height

            texCoordBuffer = @gl.createBuffer()
            @gl.bindBuffer @gl.ARRAY_BUFFER, texCoordBuffer
            @gl.bufferData @gl.ARRAY_BUFFER, new Float32Array([
                    0.0, 0.0
                    1.0, 0.0
                    0.0, 1.0
                    0.0, 1.0
                    1.0, 0.0
                    1.0, 1.0
                ]), @gl.STATIC_DRAW
            @gl.enableVertexAttribArray texCoordLocation
            @gl.vertexAttribPointer texCoordLocation, 2, @gl.FLOAT, false, 0, 0

            texture = @gl.createTexture()
            @gl.bindTexture @gl.TEXTURE_2D, texture

            @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE
            @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE
            @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST
            @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST

            @gl.texImage2D @gl.TEXTURE_2D, 0, @gl.RGBA, @gl.RGBA, @gl.UNSIGNED_BYTE, @image

            buffer = @gl.createBuffer()
            @gl.bindBuffer @gl.ARRAY_BUFFER, buffer
            @gl.enableVertexAttribArray positionLocation
            @gl.vertexAttribPointer positionLocation, 2, @gl.FLOAT, false, 0, 0
            @_setRectangle 0, 0, @image.width, @image.height
            @gl.drawArrays @gl.TRIANGLES, 0, 6

        _setRectangle: (x, y, width, height) ->
            x1 = x
            x2 = x + width
            y1 = y
            y2 = y + height
            @gl.bufferData @gl.ARRAY_BUFFER, new Float32Array([
                    x1, y1
                    x2, y1
                    x1, y2
                    x1, y2
                    x2, y1
                    x2, y2
                ]), @gl.STATIC_DRAW
