SECTIONS
{
    .text :
    {
        *(.text*)
    }

    .rodata :
    {
        *(.rodata*)
    }

    .data :
    {
        *(.data*)
    }

    .bss :
    {
        *(.bss*)
    }

    /DISCARD/ :
    {
        *(.eh_frame)
        *(.debug*)
    }
}
