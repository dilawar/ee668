#!/bin/bash 
git add -f *.tex *.pdf
git commit -m "$1"
git push
