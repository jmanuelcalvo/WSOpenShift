<?php
  $titulo = getenv('APP_HEADER'); // Gets the so var name
  $msg = getenv('APP_MSG'); // Gets the so var name

  echo "<h4>Bienvenidos a: $titulo  \r\n</h4><br>";
  echo "<p>El valor del CM/APP_MSG es: $msg  \r\n</p>"
?>
