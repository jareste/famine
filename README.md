# famine

TODO:
    - Create the service.
    - Launch the service with the daemon.
    - Build the program to iterate over the directory and apply the function.
    - Create functions to add the signature to the binary.
        It has to apply it only to ELF64 bins.
        It must verify no infection has been done into the binary.
    

    Bonus:
        - Be able to handle 32 bins it must follow same structure and logic as 64.
        - Add recursion to infect everything into the folder.
        - Launch only under certain circumstances.
        - Be able to infect non-binaries.
        - Compress the binary to make it lighter