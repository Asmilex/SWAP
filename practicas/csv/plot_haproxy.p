set terminal png size 800
set output "../img/3/haproxy_grafica.png"
set title "10000 peticiones, 10 peticiones concurrentes"
set size ratio 0.6
set grid y
set xlabel "peticiones"
set ylabel "tiempo de respuesta (ms)"
plot "haproxy_rr_g.csv" using 9 smooth sbezier with lines title "Haproxy (roundrobin)" , \
     "haproxy_weight_g.csv" using 9 smooth sbezier with lines title "Haproxy (weight)"
