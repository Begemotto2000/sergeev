#!/bin/bash
cd /home/ubuntu/upload
for f in *.txt; do
  LESSON_NUM=$(echo "$f" | sed -n 's/.*М01 Урок \([0-9]*\).*/\1/p')
  SIZE=$(wc -c < "$f")
  CHUNKS=$((SIZE / 900 + 1))
  echo "$LESSON_NUM|$f|$SIZE|$CHUNKS"
done | sort -n
