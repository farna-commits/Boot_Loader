# Details

Date : 2019-12-07 20:55:34

Directory c:\Users\osama\Desktop\Shared Folder\Project\Current\BootLoader-Skeleton\sources

Total : 30 files,  2035 codes, 290 comments, 376 blanks, all 2701 lines

[summary](results.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [boot_hello.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/boot_hello.asm) | x86 and x86_64 Assembly | 22 | 16 | 3 | 41 |
| [first_stage.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/first_stage.asm) | x86 and x86_64 Assembly | 39 | 18 | 6 | 63 |
| [includes\first_stage\bios_cls.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/bios_cls.asm) | x86 and x86_64 Assembly | 7 | 1 | 1 | 9 |
| [includes\first_stage\bios_print.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/bios_print.asm) | x86 and x86_64 Assembly | 13 | 4 | 0 | 17 |
| [includes\first_stage\bios_print_hexa.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/bios_print_hexa.asm) | x86 and x86_64 Assembly | 24 | 0 | 3 | 27 |
| [includes\first_stage\detect_boot_disk.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/detect_boot_disk.asm) | x86 and x86_64 Assembly | 23 | 6 | 1 | 30 |
| [includes\first_stage\first_stage_data.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/first_stage_data.asm) | x86 and x86_64 Assembly | 18 | 2 | 1 | 21 |
| [includes\first_stage\get_key_stroke.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/get_key_stroke.asm) | x86 and x86_64 Assembly | 6 | 1 | 0 | 7 |
| [includes\first_stage\lba_2_chs.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/lba_2_chs.asm) | x86 and x86_64 Assembly | 13 | 5 | 2 | 20 |
| [includes\first_stage\load_boot_drive_params.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/load_boot_drive_params.asm) | x86 and x86_64 Assembly | 14 | 2 | 0 | 16 |
| [includes\first_stage\read_disk_sectors.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/first_stage/read_disk_sectors.asm) | x86 and x86_64 Assembly | 31 | 8 | 3 | 42 |
| [includes\second_stage\a20_gate.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/a20_gate.asm) | x86 and x86_64 Assembly | 31 | 8 | 6 | 45 |
| [includes\second_stage\check_long_mode.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/check_long_mode.asm) | x86 and x86_64 Assembly | 54 | 1 | 7 | 62 |
| [includes\second_stage\gdt.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/gdt.asm) | x86 and x86_64 Assembly | 27 | 4 | 1 | 32 |
| [includes\second_stage\idt.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/idt.asm) | x86 and x86_64 Assembly | 9 | 1 | 2 | 12 |
| [includes\second_stage\longmode.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/longmode.asm) | x86 and x86_64 Assembly | 19 | 4 | 12 | 35 |
| [includes\second_stage\memory_scanner.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/memory_scanner.asm) | x86 and x86_64 Assembly | 72 | 5 | 7 | 84 |
| [includes\second_stage\page_table.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/page_table.asm) | x86 and x86_64 Assembly | 37 | 11 | 6 | 54 |
| [includes\second_stage\pic.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/pic.asm) | x86 and x86_64 Assembly | 15 | 0 | 2 | 17 |
| [includes\second_stage\video.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/second_stage/video.asm) | x86 and x86_64 Assembly | 23 | 2 | 3 | 28 |
| [includes\third_stage\ata.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/ata.asm) | x86 and x86_64 Assembly | 434 | 83 | 93 | 610 |
| [includes\third_stage\idt.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/idt.asm) | x86 and x86_64 Assembly | 353 | 45 | 81 | 479 |
| [includes\third_stage\pagetable2.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/pagetable2.asm) | x86 and x86_64 Assembly | 143 | 16 | 31 | 190 |
| [includes\third_stage\pci.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/pci.asm) | x86 and x86_64 Assembly | 100 | 14 | 11 | 125 |
| [includes\third_stage\pic.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/pic.asm) | x86 and x86_64 Assembly | 67 | 0 | 18 | 85 |
| [includes\third_stage\pit.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/pit.asm) | x86 and x86_64 Assembly | 38 | 0 | 8 | 46 |
| [includes\third_stage\pushaq.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/pushaq.asm) | x86 and x86_64 Assembly | 34 | 7 | 2 | 43 |
| [includes\third_stage\video.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/includes/third_stage/video.asm) | x86 and x86_64 Assembly | 128 | 13 | 8 | 149 |
| [second_stage.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/second_stage.asm) | x86 and x86_64 Assembly | 94 | 6 | 15 | 115 |
| [third_stage.asm](file:///c%3A/Users/osama/Desktop/Shared%20Folder/Project/Current/BootLoader-Skeleton/sources/third_stage.asm) | x86 and x86_64 Assembly | 147 | 7 | 43 | 197 |

[summary](results.md)