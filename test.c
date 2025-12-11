#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "life.h"

void game_of_life(int width, int height, int iterations) {

    char *board = calloc(width * height, sizeof(char));
    char *temp_board = calloc(width * height, sizeof(char));

    if (!board || !temp_board) {
        free(board);
        free(temp_board);
        return;
    }

    int x = 0;
    int y = 0;
    int drawing = 0;
    char cmd;

    while (read(STDIN_FILENO, &cmd, 1) > 0) {
        switch (cmd) {
            case 'w':
                if (y > 0) y--;
                break;
            case 's':
                if (y < height - 1) y++;
                break;
            case 'a':
                if (x > 0) x--;
                break;
            case 'd':
                if (x < width - 1) x++;
                break;
            case 'x':
                drawing = !drawing;
                break;
        }
        if (drawing)
             board[y * width + x] = 1;
    }

    for (int iter = 0; iter < iterations; iter++) {
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                int alive_neighbors = 0;

                for (int di = -1; di <= 1; di++) {
                    for (int dj = -1; dj <= 1; dj++) {
                        if (di == 0 && dj == 0) continue;

                        int ni = i + di;
                        int nj = j + dj;

                        if (ni >= 0 && ni < height && nj >= 0 && nj < width) {
                            if (board[ni * width + nj])
                                alive_neighbors++;
                            
                        }
                    }
                }

                // Get current cell state
                int current_cell = board[i * width + j];

                // Apply Conway's Game of Life rules:
                // 1. Any live cell with fewer than two live neighbors dies (underpopulation)
                // 2. Any live cell with two or three live neighbors lives on
                // 3. Any live cell with more than three live neighbors dies (overpopulation)
                // 4. Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
                if (current_cell) {  // Cell is currently alive
                    if (alive_neighbors < 2 || alive_neighbors > 3) {
                        temp_board[i * width + j] = 0;  // Dies
                    } else {
                        temp_board[i * width + j] = 1;  // Survives
                    }
                } else {  // Cell is currently dead
                    if (alive_neighbors == 3) {
                        temp_board[i * width + j] = 1;  // Becomes alive (reproduction)
                    } else {
                        temp_board[i * width + j] = 0;  // Stays dead
                    }
                }
            }
        }
        // Copy the next generation from temp_board back to board
        for (int i = 0; i < height * width; i++) 
            board[i] = temp_board[i];
        
    }

    // Output the final grid state to stdout
    // Alive cells are represented by 'O', dead cells by ' '
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            if (board[i * width + j]) {
                putchar('0');  // Alive cell
            } else {
                putchar(' ');  // Dead cell
            }
        }
        putchar('\n');  // New line after each row
    }

    // Free allocated memory
    free(board);
    free(temp_board);
}

/**
 * Main function that parses command line arguments and calls the game of life simulation
 *
 * Usage: ./program <width> <height> <iterations>
 *
 * @param argc Number of command line arguments (should be 4)
 * @param argv Array of command line arguments
 * @return 0 on success, 1 on error (invalid arguments)
 */
int main(int argc, char **argv) {
    if (argc != 4) {
        return 1;
    }

    int width = atoi(argv[1]);      // Width of the grid
    int height = atoi(argv[2]);     // Height of the grid
    int iterations = atoi(argv[3]); // Number of generations to simulate

    if (width <= 0 || height <= 0 || iterations < 0)
        return 1;  // Invalid parameters - exit with error

    game_of_life(width, height, iterations);
    return 0;
}