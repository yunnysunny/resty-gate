local util = {}

function util.str_split(logStr, delimiter)
    local i = 0
    local posStart = 1
    local delimiterLen = string.len(delimiter)
    local array = {}
    while true do
        i = string.find(logStr, delimiter, i + 1)  -- 查找下一行
        if i == nil then
            table.insert(array, string.sub(logStr,posStart,-1))
            break
        end
        table.insert(array, string.sub(logStr,posStart,i - 1))
        posStart = i + delimiterLen
    end 
    return array
end

return util