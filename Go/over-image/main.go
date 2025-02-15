// This program takes an image as input, separates it into a grid (without
// losing the aspect ratio) of N columns. It then generates a letter-size PDF
// with each of the cells of the grid. Ideal for printing handmade banners.
//
// For best results very large images are required (400 DPI for a 10000 pixels
// image with 3 columns grid). You can use open source scaling AI to process
// your images.
package main

import "github.com/signintech/gopdf"

import (
	"fmt"
	"image"
	"image/draw"
	"os"
	"strconv"

	// Codecs.
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Println(
			"Usage: over-image 3 image.png\n\n" +
				"This program requires exactly two arguments, the columns and the path to the image.")
		return
	}

	columns, err := strconv.Atoi(os.Args[1])
	if err != nil {
		panic(err)
	}

	reader, err := os.Open(os.Args[2])
	if err != nil {
		panic(err)
	}
	defer reader.Close()

	fmt.Println("Loading image...")

	imgSrc, format, err := image.Decode(reader)
	if err != nil {
		panic(err)
	}

	fmt.Println("Image format:", format)
	fmt.Printf("Image size: %dx%d\n", imgSrc.Bounds().Dx(), imgSrc.Bounds().Dy())

	// This preserves aspect ratio.
	cellWidth := imgSrc.Bounds().Dx() / columns
	cellHeight := int(float64(cellWidth) * (gopdf.PageSizeLetter.H / gopdf.PageSizeLetter.W))

	fmt.Printf("Part size: %dx%d\n", cellWidth, cellHeight)

	fmt.Println("Creating PDF...")

	pdf := gopdf.GoPdf{}
	pdf.Start(gopdf.Config{PageSize: *gopdf.PageSizeLetter})

	var partsCount int

	row := 0
	column := 0
	for cellHeight*row < imgSrc.Bounds().Dy() {
		for range columns {
			fmt.Println("Generating part:", partsCount)

			part := image.NewRGBA(image.Rect(0, 0, cellWidth, cellHeight))

			// Locate correct part.
			point := imgSrc.Bounds().Min
			point.X += column * cellWidth
			point.Y += row * cellHeight

			draw.Draw(part, part.Rect, imgSrc, point, draw.Src)

			pdf.AddPage()
			err = pdf.ImageFrom(part, 0, 0, &gopdf.Rect{W: gopdf.PageSizeLetter.W, H: gopdf.PageSizeLetter.H})
			if err != nil {
				panic(err)
			}

			column++

			partsCount++
		}

		column = 0
		row++
	}

	fmt.Println("Total parts:", partsCount)

	fmt.Println("Saving PDF...")

	pdf.WritePdf(os.Args[2] + ".pdf")
}
