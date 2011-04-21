/*
 * COPYRIGHT AND LICENSE
 *
 * Copyright (C) 2011, Georgy Bazhukov.
 *
 * This program is free software, you can redistribute it and/or modify it under
 * the terms of the Artistic License version 2.0.
 */

/*******************
*  Special for IE  *
*******************/

document.createElement('header');
document.createElement('nav');
document.createElement('article');
document.createElement('footer');

function hidden(id) {
    var a = document.getElementById(id);
    a.style.display = (a.style.display == 'block' ? 'none' : 'block');
    return false;
}
