const fs = require('fs');
const path = require('path');

const file = '/home/ubuntu/upload/МЕНТОРСТВО - М01 Урок 1. Техничка для подготовки и старта ОБНОВЛЕННЫЙ.txt';
console.log('Reading file:', file);
console.log('File size:', fs.statSync(file).size, 'bytes');

const content = fs.readFileSync(file, 'utf-8');
console.log('Content length:', content.length);
console.log('First 100 chars:', content.substring(0, 100));
