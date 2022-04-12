set terminal png size 800
set output "../img/3/pound.png"
set title "10000 peticiones, 10 peticiones concurrentes"
set size ratio 0.6
set grid y
set xlabel "peticiones"
set ylabel "tiempo de respuesta (ms)"
plot "pound_rr_g.csv" using 9 smooth sbezier with lines title "Pound (roundrobin)" , \
     "pound_weight_g.csv" using 9 smooth sbezier with lines title "Pound (weight)"
