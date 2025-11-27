#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "life.h"

void game_of_life(int width, int height, int iterations) {
    char *board = calloc(width * height, sizeof(char));
    char *temp_board = calloc(width * height, sizeof(char));
    if (!board || !temp_board) {
        free(board);
        free(temp_board);
        return ;
    }

    int x = 0 ;
    int y = 0 ;
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
                        if (di == 0 && dj == 0) continue ;

                        int ni = i + di;
                        int nj = j + dj;

                        if (ni >= 0 && ni < height && nj >= 0 && nj < width) {
                            if (board[ni * width + nj])
                                alive_neighbors++;
                        }
                    }
                }
                int current_cell = board[i * width + j];

                if (current_cell) {
                    if (alive_neighbors < 2 || alive_neighbors > 3)
                        temp_board[i * width + j] = 0;
                    else
                        temp_board[i * width + j] = 1;
                } else {
                    if (alive_neighbors == 3)
                        temp_board[i * width + j] = 1;
                    else
                        temp_board[i * width + j] = 0;
                }
            }
        }
        for (int i = 0; i < height * width; i++)
            board[i] = temp_board[i];
    }

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            if (board[i * width + j])
                putchar('0');
            else
                putchar(' ');
        }
        putchar('\n');
    }

    free(board);
    free(temp_board);
}

int main(int argc, char **argv)
{
    if (argc != 4)
        return (1);

    int width = atoi(argv[1]);
    int height = atoi(argv[2]);
    int iterations = atoi(argv[3]);

    if (width <= 0 || height <= 0 || iterations < 0)
        return (1);

    game_of_life(width, height, iterations);
    return (0);
}