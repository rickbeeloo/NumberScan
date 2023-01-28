using Mmap

struct numberScan 
    arr::AbstractVector{UInt8} # We can work with memory views
    del::Char
end 

function mmapScan(f::String, del::Char)
    # Since we scan bytes arrays we can also mmap a file to quickly
    # scan large files for numbers without loading in RAM
    isfile(f) || error("This is not a file")
    map_vect = mmap(open(f, "r"), Vector{UInt8}, filesize(f))
    return numberScan(map_vect, del)
end

function _memchr(mem::AbstractVector{UInt8}, byte::UInt8 ; from_index::Int64 = 1)
    # memchar function in C can scan a memory block (in bytes) for a specific byte
    # it does this from a starting location (mem_start_at) and scans the next X, bytes
    # where X is the mem_bytes_left. Similar to base findfirst but then without 
    # any safety checks for speed
    p = pointer(mem)
    mem_size = sizeof(mem)
    mem_start_at = p + from_index - 1
    mem_bytes_left = mem_size-from_index+1
    q = GC.@preserve mem @ccall memchr(mem_start_at::Ptr{UInt8}, byte::Cint, mem_bytes_left::Csize_t)::Ptr{Cchar}
    # Using % to type convert is unsafe, but since we now our input is safe this will save some instructions again :)
    # maybe for now keep this save but we can change it back:
    # (q % Int64) - (p % Int64) + Int64(1)
    return q == C_NULL ? Int64(0) : Int64(q - p + 1)
end

function _atoi(char_slice::AbstractVector{UInt8})
    # C's atoi is probably the fastest way to convert any char string to a number
    # this can also include non-numeric bytes, like +, -, ? etc. which will be automatically 
    # discarded
    return GC.@preserve char_slice @ccall atoi(pointer(char_slice)::Cstring)::Int64 
end

@inline function _process_result(numby::numberScan, from::Int64, to::Int64)
    to == 0 && return @inbounds _atoi(view(numby.arr, from:sizeof(numby.arr))), sizeof(numby.arr)
    return @inbounds _atoi(view(numby.arr, from:to-1)), to + 1 
end

@inline function Base.iterate(numby::numberScan)
    # We search for the first occurence of the delimiter 
    pos = _memchr(numby.arr, UInt8(numby.del))
    return _process_result(numby, 1, pos)
end     

@inline function Base.iterate(numby::numberScan, state::Int64)
    state >= length(numby.arr) && return nothing 
    # Search for the next occurence, for this we move the 
    # memchr pointer in memchr
    pos = _memchr(numby.arr, UInt8(numby.del), from_index=state)
    return _process_result(numby, state, pos)
end
