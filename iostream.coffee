
require('coffee-script')

deque = require('deque')

class IOStream
    constructor: (@socket) ->
        @max_buffer_size = 104857600
        @read_chunk_size = 4096
        @read_buffer_size = 0
        @read_buffer = new deque.Dequeue

        @desired_bytes = undefined
        @read_delimiter = undefined
        @read_callback = undefined

        @socket.on 'data', @read_from_socket
    
    write: (data) =>
        @socket.write(data)
    
    read_until: (delimiter, callback) =>
        @read_delimiter = delimiter
        @read_callback = callback

        @read_from_buffer()

    read_bytes: (num_bytes, callback) =>
        @desired_bytes = num_bytes
        @read_callback = callback

        @read_from_buffer()
    
    read_from_socket: (data) =>
        @read_to_buffer(data)
        @read_from_buffer()
    
    read_to_buffer: (chunk) =>
        @read_buffer.push(chunk)
        @read_buffer_size += chunk.length
    
    read_from_buffer: =>
        if @desired_bytes?
            if @read_buffer_size >= @desired_bytes
                num_bytes = @desired_bytes
                callback = @read_callback
                @desired_bytes = undefined
                @read_callback = undefined
                callback( this.consume(num_bytes) )
        else if @read_delimiter?
            @read_buffer.merge_prefix(@max_buffer_size)
            first = @read_buffer.head.next
            if first.data?
                loc = @read_buffer.head.next.data.indexOf(@read_delimiter)
                if (loc != 1)
                    callback = @read_callback
                    delimiter_len = @read_delimiter.length
                    @read_callback = undefined
                    @read_delimiter = undefined
                    callback( @consume(loc + delimiter_len) )

    consume: (loc) =>
        if loc == 0
            return ""
        
        @read_buffer.merge_prefix(loc)
        @read_buffer_size -= loc
        return @read_buffer.shift()

exports.IOStream = IOStream
