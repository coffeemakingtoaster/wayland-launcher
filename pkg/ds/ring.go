package ds

import (
	"errors"
	"time"
)

type RingNode[T any] struct {
	next         *RingNode[T]
	val          *T
	insertedUnix int64
}

func (rn *RingNode[T]) ttlExceeded(ttl int64) bool {
	if ttl < 0 {
		return false
	}
	return time.Now().Unix()-rn.insertedUnix > ttl
}

type Ring[T any] struct {
	root               *RingNode[T]
	currentSize        int
	desiredMaxCapacity int
	ttl                int64
}

func NewRing[T any](size int, ttl int64) (*Ring[T], error) {
	if size == 0 {
		return nil, errors.New("What do you even need me for?")
	}
	return &Ring[T]{
		root:               nil,
		currentSize:        0,
		desiredMaxCapacity: size,
		ttl:                ttl,
	}, nil
}

func (r *Ring[T]) GetCurrentSize() int {
	return r.currentSize
}

func (r *Ring[T]) Insert(value *T) {
	if r.currentSize < r.desiredMaxCapacity {
		r.fill(value)
	} else {
		r.insertAndShift(value)
	}
}

func (r *Ring[T]) insertAndShift(value *T) {
	last := r.getLast()
	last.val = value
	last.insertedUnix = time.Now().Unix()
	r.root = last
}

func (r *Ring[T]) fill(value *T) {
	newNode := &RingNode[T]{
		val:          value,
		next:         nil,
		insertedUnix: time.Now().Unix(),
	}
	if r.root == nil {
		newNode.next = newNode
		r.root = newNode
	} else {
		last := r.getLast()
		last.next = newNode
		newNode.next = r.root
	}

	r.currentSize += 1
}

func (r *Ring[T]) getLast() *RingNode[T] {
	if r.root == nil {
		return nil
	}
	curr := r.root
	for curr.next != r.root {
		curr = curr.next
	}
	return curr
}

func (r *Ring[T]) GetValuesInOrder() []T {
	result := make([]T, r.currentSize) // includes dead elements
	curr := r.root
	i := 0
	for i < len(result) {
		if curr.ttlExceeded(r.ttl) {
			result = result[:i]
			break
		}
		result[i] = *curr.val
		curr = curr.next
		i = i + 1
	}
	return result
}
