package main

import (
	"fmt"
	"image/color"
	"log"
	"math/rand/v2"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/ebitenutil"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
)

const cellSize = 32

const maxLevel = 32

type tile struct {
	x, y  int
	level int
}

type Game struct {
	x, y          int
	eneX, eneY    int
	width, height int
	ticks         int
	gameOver      bool
	tiles         []tile
	blocks        []tile
}

func (g *Game) Update() error {
	if g.gameOver {
		if inpututil.IsKeyJustPressed(ebiten.KeyEnter) {
			*g = Game{eneX: 9999, eneY: 9999}
		}
		return nil
	}

	g.ticks++

	lastX, lastY := g.x, g.y

	x, y := g.Cells()
	if inpututil.IsKeyJustPressed(ebiten.KeyQ) {
		return fmt.Errorf("exit")
	}
	if inpututil.IsKeyJustPressed(ebiten.KeyW) {
		g.y = max(0, g.y-1)
	}
	if inpututil.IsKeyJustPressed(ebiten.KeyA) {
		g.x = max(0, g.x-1)
	}
	if inpututil.IsKeyJustPressed(ebiten.KeyS) {
		g.y = min(y-1, g.y+1)
	}
	if inpututil.IsKeyJustPressed(ebiten.KeyD) {
		g.x = min(x-1, g.x+1)
	}

	for _, tile := range g.blocks {
		if g.x == tile.x && g.y == tile.y {
			g.x = lastX
			g.y = lastY
			break
		}
	}

	var hasTile bool
	for i := range g.tiles {
		if g.tiles[i].x == g.x && g.tiles[i].y == g.y && g.tiles[i].level > 0 {
			g.x = lastX
			g.y = lastY
		}

		if g.tiles[i].x == lastX && g.tiles[i].y == lastY {
			hasTile = true
			g.tiles[i].level = maxLevel
		}
	}

	if !hasTile {
		g.tiles = append(g.tiles, tile{lastX, lastY, maxLevel})
	}

	if g.ticks == 60/6 {
		for i := range g.tiles {
			if g.tiles[i].level > 0 {
				g.tiles[i].level--
			}
		}

		if g.x < g.eneX {
			g.eneX = max(0, g.eneX-1)
		} else {
			g.eneX = min(x-1, g.eneX+1)
		}

		if g.y < g.eneY {
			g.eneY = max(0, g.eneY-1)
		} else {
			g.eneY = min(y-1, g.eneY+1)
		}
	}

	if g.ticks == 60/3 {
		g.ticks = 0
		g.eneX = min(x-1, max(g.eneX+rand.IntN(2)+(-1)*rand.IntN(2), 0))
		g.eneY = min(y-1, max(g.eneY+rand.IntN(2)+(-1)*rand.IntN(2), 0))

		if rand.IntN(5) == 0 {
			g.blocks = append(g.blocks, tile{g.eneX, g.eneY, -1})
		}
	}

	if g.x == g.eneX && g.y == g.eneY {
		g.gameOver = true
	}

	return nil
}

func (g *Game) Draw(screen *ebiten.Image) {
	screen.Fill(color.Black)

	if g.gameOver {
		ebitenutil.DebugPrint(screen, fmt.Sprintf(`
	Has perdido.
		Usa WASD para moverte.
		Usa Intro para nueva partida.

	Puntaje: %d
	`, len(g.blocks)))
		return
	}

	for _, tile := range g.tiles {
		img := ebiten.NewImage(cellSize, cellSize)
		img.Fill(color.RGBA{0, 255 / maxLevel * uint8(tile.level), 0, 255})
		geoM := ebiten.GeoM{}
		geoM.Translate(float64(tile.x*cellSize), float64(tile.y*cellSize))
		screen.DrawImage(img, &ebiten.DrawImageOptions{GeoM: geoM})
	}

	for _, tile := range g.blocks {
		img := ebiten.NewImage(cellSize, cellSize)
		img.Fill(color.RGBA{255, 0, 255, 255})
		geoM := ebiten.GeoM{}
		geoM.Translate(float64(tile.x*cellSize), float64(tile.y*cellSize))
		screen.DrawImage(img, &ebiten.DrawImageOptions{GeoM: geoM})
	}

	img := ebiten.NewImage(cellSize, cellSize)
	img.Fill(color.White)
	geoM := ebiten.GeoM{}
	geoM.Translate(float64(g.x*cellSize), float64(g.y*cellSize))
	screen.DrawImage(img, &ebiten.DrawImageOptions{GeoM: geoM})

	img = ebiten.NewImage(cellSize, cellSize)
	img.Fill(color.RGBA{255, 0, 0, 255})
	geoM = ebiten.GeoM{}
	geoM.Translate(float64(g.eneX*cellSize), float64(g.eneY*cellSize))
	screen.DrawImage(img, &ebiten.DrawImageOptions{GeoM: geoM})

	x, y := g.Cells()
	ebitenutil.DebugPrint(screen, fmt.Sprintln(g.width, "x", g.height, "Cells:", x, "x", y, "Pos:", g.x, "x", g.y, "FPS:", ebiten.ActualFPS()))
}

func (g *Game) Layout(outsideWidth, outsideHeight int) (screenWidth, screenHeight int) {
	// g.width = outsideWidth
	// g.height = outsideHeight
	g.width = 800
	g.height = 600
	return g.width, g.height
}

func (g *Game) Cells() (x, y int) {
	return g.width / cellSize, g.height / cellSize
}

func main() {
	ebiten.SetWindowSize(800, 600)
	ebiten.SetWindowTitle("Enbite Practice")
	if err := ebiten.RunGame(&Game{gameOver: true}); err != nil {
		log.Fatal(err)
	}
}
