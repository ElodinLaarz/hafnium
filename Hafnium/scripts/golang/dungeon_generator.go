package main

import (
	"fmt"
	"math/rand"
)

type binaryRoom struct {
	// A binary room either is a leaf (and thus a room) or has two children.
	room *Room
	// The children describe how the room is split.
	left  *binaryRoom
	right *binaryRoom
}

// Dungeon is a collection of rooms and corridors.
type Dungeon struct {
	minRoomSideLength int // When generating our rooms, we want to make sure they are at least this big.
	roomTree          binaryRoom
}

type Room struct {
	// For now, rooms will be rectangular.
	// The top left corner of the room.
	Location [2]int
	// The width and height of the room.
	Size [2]int
}

func splitHorizontallyNoBoundsCheck(room *Room) *binaryRoom {
	horizontalSize := room.Size[0]
	verticalSize := room.Size[1]
	// Split horizontally.
	// The top room will be the same width and half the height.
	topRoom := Room{room.Location, [2]int{horizontalSize, verticalSize / 2}}
	// The bottom room will be the same width and half the height.
	bottomRoom := Room{[2]int{room.Location[0], room.Location[1] + verticalSize/2}, [2]int{horizontalSize, verticalSize / 2}}
	return &binaryRoom{room, &binaryRoom{room: &topRoom}, &binaryRoom{room: &bottomRoom}}
}

func splitVerticallyNoBoundsCheck(room *Room) *binaryRoom {
	horizontalSize := room.Size[0]
	verticalSize := room.Size[1]
	// Split vertically.
	// The left room will be the same height and half the width.
	leftRoom := Room{room.Location, [2]int{horizontalSize / 2, verticalSize}}
	// The right room will be the same height and half the width.
	rightRoom := Room{[2]int{room.Location[0] + horizontalSize/2, room.Location[1]}, [2]int{horizontalSize / 2, verticalSize}}
	return &binaryRoom{room, &binaryRoom{room: &leftRoom}, &binaryRoom{room: &rightRoom}}
}

func (d *Dungeon) splitRoom(room *Room) (*binaryRoom, error) {
	// Split the dungeon into rooms.
	minSideLength := d.minRoomSideLength
	horizontalSize := room.Size[0]
	verticalSize := room.Size[1]
	// First choose to split the room horizontally or vertically.
	mustSplitHorizontally := verticalSize <= minSideLength
	mustSplitVertically := horizontalSize <= minSideLength
	if mustSplitHorizontally && mustSplitVertically {
		return nil, fmt.Errorf("Room is too small to split.")
	}
	// Randomly choose to split horizontally or vertically.
	chosenSplit := rand.Intn(2) // 0 == horizontal, 1 == vertical
	choseVertical := chosenSplit == 1 && !mustSplitHorizontally
	choseHorizontal := chosenSplit == 0 && !mustSplitVertically

	if mustSplitHorizontally || choseHorizontal {
		return splitHorizontallyNoBoundsCheck(room), nil
	}
	if mustSplitVertically || choseVertical {
		return splitVerticallyNoBoundsCheck(room), nil
	}
	return nil, fmt.Errorf("Failed to split room.") // This should never happen.
}

func main() {
	fmt.Println("Hello, World!")
}
