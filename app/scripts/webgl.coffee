define ->
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
            resolutionLocation = @gl.getUniformLocation @shaderProgram, 'u_resolution'
            @gl.uniform2f resolutionLocation, @width, @height

            buffer = @gl.createBuffer()
            @gl.bindBuffer @gl.ARRAY_BUFFER, buffer
            @gl.bufferData @gl.ARRAY_BUFFER, new Float32Array([
                    10, 20
                    80, 20
                    10, 30
                    10, 30
                    80, 20
                    80,30
                ]),
                @gl.STATIC_DRAW

            @gl.enableVertexAttribArray positionLocation
            @gl.vertexAttribPointer positionLocation, 2, @gl.FLOAT, false, 0, 0

            @gl.drawArrays @gl.TRIANGLES, 0, 6
