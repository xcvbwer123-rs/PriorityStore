--#[ Types ]#--
export type Heap<T=any> = {
    id: string,
    value: T,
    priority: number,
    _seq: number,
}

type StoreImpl<T = any> = {
    __index: StoreImpl<T>;

    new: () -> Store<T>;
    add: (
        self: Store<T>,
        id: string,
        initialValue: T,
        priority: number
    ) -> Heap<T>;
    set: (
        self: Store<T>,
        id: string,
        value: T
    ) -> boolean;
    get: (
        self: Store<T>,
        id: string
    ) -> T?;
    getTop: (
        self: Store<T>
    ) -> T?;
    remove: (
        self: Store<T>,
        id: string
    ) -> T?;
    size: (
        self: Store<T>
    ) -> number;
}

export type Store<T = any> = typeof(setmetatable({} :: {
    _heap: { Heap<T> };
    _index: { [string]: number };
    _seq: number;
}, {} :: StoreImpl<T>))

local storeImpl = {} :: StoreImpl
storeImpl.__index = storeImpl

local function higher(
    a: Heap<any>,
    b: Heap<any>
): boolean
    if a.priority ~= b.priority then
        return a.priority > b.priority
    end

    return a._seq > b._seq
end

local function swap<T>(
    self: Store<T>,
    i: number,
    j: number
)
    local heap = self._heap

    heap[i], heap[j] = heap[j], heap[i]

    self._index[heap[i].id] = i
    self._index[heap[j].id] = j
end

local function heapifyUp<T>(
    self: Store<T>,
    i: number
)
    while i > 1 do
        local parent = math.floor(i / 2)

        if higher(self._heap[i], self._heap[parent]) then
            swap(self, i, parent)
            i = parent
        else
            break
        end
    end
end

local function heapifyDown<T>(
    self: Store<T>,
    i: number
)
    local n = #self._heap

    while true do
        local left = 2 * i
        local right = left + 1
        local largest = i

        if left <= n and higher(self._heap[left], self._heap[largest]) then
            largest = left
        end

        if right <= n and higher(self._heap[right], self._heap[largest]) then
            largest = right
        end

        if largest ~= i then
            swap(self, i, largest)
            i = largest
        else
            break
        end
    end
end

function storeImpl.new<T>(): Store<T>
    -- return setmetatable(
    --     {
    --         _heap = {} :: { Heap<T> },
    --         _index = {} :: { [string]: number },
    --         _seq = 0,
    --     },
    --     storeImpl
    -- )

    local self = {}

    self._heap = {}
    self._index = {}
    self._seq = 0

    return setmetatable(self, storeImpl)
end

function storeImpl:add<T>(
    id: string,
    initialValue: T,
    priority: number
)
    local seq = self._seq + 1
    self._seq = seq

    local index = self._index[id]

    if index == nil then
        local node: Heap<T> = {
            id = id;
            value = initialValue;
            priority = priority;
            _seq = seq;
        }

        table.insert(self._heap, node)

        local newIndex = #self._heap
        self._index[id] = newIndex

        heapifyUp(self, newIndex)
        
        return node
    else
        local node = self._heap[index]

        node.value = initialValue
        node.priority = priority
        node._seq = seq
        
        heapifyUp(self, index)

        index = self._index[id]

        heapifyDown(self, index)
        
        return node
    end
end

function storeImpl:set<T>(
    id: string,
    value: T
): boolean
    local index = self._index[id]

    if index ~= nil then
        local heap = self._heap[index]

        if heap.value ~= value then
            heap.value = value
            return true
        end
    end

    return true
end

function storeImpl:get<T>(id: string): T?
    local index = self._index[id]

    if index == nil then
        return nil
    end

    return self._heap[index].value
end

function storeImpl:getTop<T>(): T?
    local topNode = self._heap[1]

    if topNode then
        return topNode.value
    end

    return nil
end

function storeImpl:remove<T>(id: string): T?
    local index = self._index[id]

    if index ~= nil then
        local heap = self._heap
        local lastIndex = #heap

        swap(self, index, lastIndex)

        local removedNode = table.remove(heap, lastIndex) :: Heap<T>

        self._index[removedNode.id] = nil

        if index <= #heap then
            heapifyUp(self, index)
            heapifyDown(self, index)
        end

        return removedNode.value
    else
        return nil
    end
end

function storeImpl:size(): number
    return #self._heap
end

return storeImpl