

.model small
.stack 100h
.data
    ; Display settings
    BLOCK_SIZE equ 1
    GRID_WIDTH equ 80
    GRID_HEIGHT equ 25
    MAX_SNAKE_LENGTH equ 180
    
    BLACK equ 0
    GREEN equ 10
    RED equ 12
    WHITE equ 15
    BLUE equ 9
    YELLOW equ 14
    
    ; Snake arrays
    snakeX db MAX_SNAKE_LENGTH dup(?)
    snakeY db MAX_SNAKE_LENGTH dup(?)
    snakeLength dw 3
    
    ; Direction: 0=Right, 1=Down, 2=Left, 3=Up
    direction db 0
    
    ; Food position
    foodX db ?
    foodY db ?
    
    ; Game state
    gameOver db 0
    score dw 0
    
    ; Random seed
    rand_seed dw 0
    
    ; Messages
    msg_title db 'SNAKE GAME$'
    msg_game_text db 'GAME$'
    msg_over_text db 'OVER!$'
    msg_score_label db 'Score: $'
    msg_final_score db 'Final Score: $'

.code
main proc
    mov ax, @data
    mov ds, ax
    
    call setup
    
game_loop:
    cmp gameOver, 1
    jne continue_game
    
    call displayGameOver
    
    ; Wait for any key to restart
    mov ah, 0
    int 16h
    
    call initGame
    
    ; Clear screen
    mov ah, 0
    mov al, 3
    int 10h
    
    call draw_border
    
continue_game:
    ; Read keyboard multiple times for better responsiveness
    call readKeyboard
    call readKeyboard
    call readKeyboard
    call readKeyboard
    call readKeyboard
    
    call moveSnake
    call checkCollision
    
    cmp gameOver, 1
    je game_loop
    
    call checkFood
    call drawGame
    
    ; No delay - maximum speed
    
    jmp game_loop

main endp

; Setup function (like Arduino setup())
setup proc
    push ax
    
    ; Set video mode (80x25 text)
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Hide cursor
    mov ah, 1
    mov ch, 32
    int 10h
    
    ; Initialize random seed
    mov ah, 0
    int 1ah
    mov rand_seed, dx
    
    ; Initialize game
    call initGame
    
    ; Draw border once
    call draw_border
    
    pop ax
    ret
setup endp

; Initialize game
initGame proc
    push ax
    push bx
    push cx
    
    mov snakeLength, 3
    mov direction, 0      ; Start going RIGHT
    mov gameOver, 0
    mov score, 0
    
    ; Snake starts going RIGHT (head to the right of body)
    ; Body segment 2 at (38, 12) - leftmost
    mov snakeX[2], 38
    mov snakeY[2], 12
    
    ; Body segment 1 at (39, 12) - middle
    mov snakeX[1], 39
    mov snakeY[1], 12
    
    ; Head at (40, 12) - rightmost, will move right
    mov snakeX[0], 40
    mov snakeY[0], 12
    
    call spawnFood
    
    pop cx
    pop bx
    pop ax
    ret
initGame endp

; Read keyboard (like readJoystick)
readKeyboard proc
    push ax
    
    ; Check for key press
    mov ah, 1
    int 16h
    jz no_key_pressed
    
    ; Get key
    mov ah, 0
    int 16h
    
    ; Check arrow keys
    cmp ah, 4dh    ; Right arrow
    je set_right
    cmp ah, 4bh    ; Left arrow
    je set_left
    cmp ah, 48h    ; Up arrow
    je set_up
    cmp ah, 50h    ; Down arrow
    je set_down
    cmp al, 27     ; ESC key
    je exit_program
    jmp no_key_pressed
    
set_right:
    cmp direction, 2  ; Can't go right if going left
    je no_key_pressed
    mov direction, 0
    jmp no_key_pressed
    
set_left:
    cmp direction, 0  ; Can't go left if going right
    je no_key_pressed
    mov direction, 2
    jmp no_key_pressed
    
set_up:
    cmp direction, 1  ; Can't go up if going down
    je no_key_pressed
    mov direction, 3
    jmp no_key_pressed
    
set_down:
    cmp direction, 3  ; Can't go down if going up
    je no_key_pressed
    mov direction, 1
    jmp no_key_pressed
    
exit_program:
    ; Show cursor
    mov ah, 1
    mov ch, 6
    mov cl, 7
    int 10h
    
    ; Exit to DOS
    mov ah, 4ch
    int 21h
    
no_key_pressed:
    pop ax
    ret
readKeyboard endp

; Move snake
moveSnake proc
    push ax
    push bx
    push cx
    
    ; Shift snake body
    mov cx, snakeLength
    dec cx
    mov bx, cx
    
shift_body:
    cmp bx, 0
    jle move_head
    
    mov al, snakeX[bx-1]
    mov snakeX[bx], al
    mov al, snakeY[bx-1]
    mov snakeY[bx], al
    
    dec bx
    jmp shift_body
    
move_head:
    ; Move head based on direction
    mov al, snakeX[0]
    mov ah, snakeY[0]
    
    cmp direction, 0
    je move_right
    cmp direction, 1
    je move_down
    cmp direction, 2
    je move_left
    jmp move_up
    
move_right:
    inc al
    jmp update_position
move_down:
    inc ah
    jmp update_position
move_left:
    dec al
    jmp update_position
move_up:
    dec ah
    
update_position:
    mov snakeX[0], al
    mov snakeY[0], ah
    
    pop cx
    pop bx
    pop ax
    ret
moveSnake endp

; Check collision
checkCollision proc
    push ax
    push bx
    push cx
    
    ; Wall collision
    mov al, snakeX[0]
    cmp al, 1
    jle hit_wall
    cmp al, GRID_WIDTH-2
    jge hit_wall
    
    mov al, snakeY[0]
    cmp al, 1
    jle hit_wall
    cmp al, GRID_HEIGHT-2
    jge hit_wall
    
    ; Self collision
    mov cx, snakeLength
    mov bx, 1
    
check_self_loop:
    cmp bx, cx
    jge no_collision
    
    mov al, snakeX[0]
    cmp al, snakeX[bx]
    jne next_segment
    
    mov al, snakeY[0]
    cmp al, snakeY[bx]
    jne next_segment
    
    ; Hit yourself!
    mov gameOver, 1
    jmp collision_end
    
next_segment:
    inc bx
    jmp check_self_loop
    
hit_wall:
    mov gameOver, 1
    jmp collision_end
    
no_collision:
    
collision_end:
    pop cx
    pop bx
    pop ax
    ret
checkCollision endp

; Check food
checkFood proc
    push ax
    
    mov al, snakeX[0]
    cmp al, foodX
    jne no_food_eaten
    
    mov al, snakeY[0]
    cmp al, foodY
    jne no_food_eaten
    
    ; Increase length and score
    mov ax, snakeLength
    cmp ax, MAX_SNAKE_LENGTH
    jge no_food_eaten
    
    inc snakeLength
    add score, 10
    
    call spawnFood
    
no_food_eaten:
    pop ax
    ret
checkFood endp

; Spawn food
spawnFood proc
    push ax
    push bx
    push cx
    push dx
    
spawn_retry:
    ; Generate random X position (1 to GRID_WIDTH-2)
    call random
    mov ax, dx
    mov dx, 0
    mov cx, GRID_WIDTH-3
    div cx
    add dl, 1
    mov foodX, dl
    
    ; Generate random Y position (1 to GRID_HEIGHT-2)
    call random
    mov ax, dx
    mov dx, 0
    mov cx, GRID_HEIGHT-3
    div cx
    add dl, 1
    mov foodY, dl
    
    ; Check if food spawns on snake
    mov cx, snakeLength
    mov bx, 0
    
check_snake_collision:
    cmp bx, cx
    jge valid_position
    
    mov al, foodX
    cmp al, snakeX[bx]
    jne check_next
    
    mov al, foodY
    cmp al, snakeY[bx]
    jne check_next
    
    ; Invalid position, retry
    jmp spawn_retry
    
check_next:
    inc bx
    jmp check_snake_collision
    
valid_position:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
spawnFood endp

; Draw game
drawGame proc
    push ax
    push bx
    push cx
    push dx
    
    ; Erase tail
    mov bx, snakeLength
    dec bx
    
    mov dl, snakeX[bx]
    mov dh, snakeY[bx]
    
    cmp dl, 0
    jle skip_erase
    cmp dl, GRID_WIDTH
    jge skip_erase
    cmp dh, 0
    jle skip_erase
    cmp dh, GRID_HEIGHT
    jge skip_erase
    
    call setCursor
    
    mov ah, 9
    mov al, ' '
    mov bh, 0
    mov bl, BLACK
    mov cx, 1
    int 10h
    
skip_erase:
    ; Draw head
    mov dl, snakeX[0]
    mov dh, snakeY[0]
    call setCursor
    
    mov ah, 9
    mov al, 219    ; Block character
    mov bh, 0
    mov bl, GREEN
    mov cx, 1
    int 10h
    
    ; Draw food
    mov dl, foodX
    mov dh, foodY
    call setCursor
    
    mov ah, 9
    mov al, 4      ; Diamond character
    mov bh, 0
    mov bl, RED
    mov cx, 1
    int 10h
    
    ; Display score
    mov dh, 0
    mov dl, 35
    call setCursor
    
    mov ah, 9
    lea dx, msg_score_label
    int 21h
    
    mov ax, score
    call printNumber
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawGame endp

; Display game over
displayGameOver proc
    push ax
    push dx
    
    ; Clear screen
    mov ah, 0
    mov al, 3
    int 10h
    
    ; Display "GAME"
    mov dh, 9
    mov dl, 37
    call setCursor
    
    mov ah, 9
    lea dx, msg_game_text
    int 21h
    
    ; Display "OVER!"
    mov dh, 11
    mov dl, 37
    call setCursor
    
    mov ah, 9
    lea dx, msg_over_text
    int 21h
    
    ; Display final score
    mov dh, 15
    mov dl, 32
    call setCursor
    
    mov ah, 9
    lea dx, msg_final_score
    int 21h
    
    mov ax, score
    call printNumber
    
    pop dx
    pop ax
    ret
displayGameOver endp

; Draw border
draw_border proc
    push ax
    push bx
    push cx
    push dx
    
    ; Draw top and bottom borders simultaneously
    mov cx, GRID_WIDTH
    mov dl, 0
    
horizontal_borders:
    ; Top border
    mov dh, 0
    call setCursor
    mov ah, 9
    mov al, 205
    mov bl, WHITE
    mov bh, 0
    push cx
    mov cx, 1
    int 10h
    
    ; Bottom border (same column)
    mov dh, GRID_HEIGHT-1
    call setCursor
    mov ah, 9
    mov al, 205
    mov bl, WHITE
    mov bh, 0
    mov cx, 1
    int 10h
    
    pop cx
    inc dl
    loop horizontal_borders
    
    ; Draw left and right borders simultaneously
    mov cx, GRID_HEIGHT-2
    mov dh, 1
    
vertical_borders:
    ; Left border
    mov dl, 0
    call setCursor
    mov ah, 9
    mov al, 186
    mov bl, WHITE
    mov bh, 0
    push cx
    mov cx, 1
    int 10h
    
    ; Right border (same row)
    mov dl, GRID_WIDTH-1
    call setCursor
    mov ah, 9
    mov al, 186
    mov bl, WHITE
    mov bh, 0
    mov cx, 1
    int 10h
    
    pop cx
    inc dh
    loop vertical_borders
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_border endp

; Set cursor position (DH=row, DL=col)
setCursor proc
    push ax
    push bx
    
    mov ah, 2
    mov bh, 0
    int 10h
    
    pop bx
    pop ax
    ret
setCursor endp

; Print number in AX
printNumber proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
divide_num:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne divide_num
    
print_digits:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
printNumber endp

; Random number generator
random proc
    push ax
    push cx
    
    mov ax, rand_seed
    mov cx, 25173
    mul cx
    add ax, 13849
    mov rand_seed, ax
    mov dx, ax
    
    pop cx
    pop ax
    ret
random endp

; Delay routine (minimal CPU-based delay)
delay proc
    push cx
    
    mov cx, 1000    ; Small loop for minimal delay
delay_loop_inner:
    loop delay_loop_inner
    
    pop cx
    ret
delay endp

end main