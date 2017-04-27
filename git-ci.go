package main

import "fmt"
import "git"
import "os"

func main() {
    repo, err := git.OpenRepository(".")
    if err != nil {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
    }

    head,   err := repo.References.Lookup("HEAD")
    object, err := head.Peel(git.ObjectCommit)
    commit, err := object.AsCommit()
    fmt.Printf("%s is the best.\n", commit.Author().Name)
}
