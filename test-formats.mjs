#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Парсер SRT
function parseSRT(content) {
  const blocks = content.split('\n\n').filter(block => block.trim());
  const segments = [];
  
  for (const block of blocks) {
    const lines = block.split('\n');
    if (lines.length >= 3) {
      const timeMatch = lines[1].match(/(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})/);
      if (timeMatch) {
        const text = lines.slice(2).join(' ').trim();
        segments.push({
          startTime: lines[1].split(' --> ')[0],
          endTime: lines[1].split(' --> ')[1],
          text: text,
          startMs: parseInt(timeMatch[1]) * 3600000 + parseInt(timeMatch[2]) * 60000 + parseInt(timeMatch[3]) * 1000 + parseInt(timeMatch[4]),
          endMs: parseInt(timeMatch[5]) * 3600000 + parseInt(timeMatch[6]) * 60000 + parseInt(timeMatch[7]) * 1000 + parseInt(timeMatch[8])
        });
      }
    }
  }
  
  return segments;
}

// Парсер VTT
function parseVTT(content) {
  const lines = content.split('\n');
  const segments = [];
  let i = 0;
  
  // Пропустить заголовок WEBVTT
  while (i < lines.length && !lines[i].includes('-->')) {
    i++;
  }
  
  while (i < lines.length) {
    const line = lines[i];
    if (line.includes('-->')) {
      const timeMatch = line.match(/(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})/);
      if (timeMatch) {
        i++;
        const textLines = [];
        while (i < lines.length && lines[i].trim() !== '') {
          textLines.push(lines[i]);
          i++;
        }
        const text = textLines.join(' ').trim();
        
        segments.push({
          startTime: line.split(' --> ')[0],
          endTime: line.split(' --> ')[1],
          text: text,
          startMs: parseInt(timeMatch[1]) * 3600000 + parseInt(timeMatch[2]) * 60000 + parseInt(timeMatch[3]) * 1000 + parseInt(timeMatch[4]),
          endMs: parseInt(timeMatch[5]) * 3600000 + parseInt(timeMatch[6]) * 60000 + parseInt(timeMatch[7]) * 1000 + parseInt(timeMatch[8])
        });
      }
    }
    i++;
  }
  
  return segments;
}

// Парсер CSV
function parseCSV(content) {
  const lines = content.split('\n');
  const segments = [];
  
  // Пропустить заголовок
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    // Парсить CSV с кавычками
    const match = line.match(/"(\d+)","(\d+)","(.+?)"\s*$/);
    if (match) {
      const startMs = parseInt(match[1]);
      const endMs = parseInt(match[2]);
      const text = match[3].trim();
      
      segments.push({
        startTime: formatTime(startMs),
        endTime: formatTime(endMs),
        text: text,
        startMs: startMs,
        endMs: endMs
      });
    }
  }
  
  return segments;
}

function formatTime(ms) {
  const hours = Math.floor(ms / 3600000);
  const minutes = Math.floor((ms % 3600000) / 60000);
  const seconds = Math.floor((ms % 60000) / 1000);
  const milliseconds = ms % 1000;
  
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')},${String(milliseconds).padStart(3, '0')}`;
}

// Тестирование
async function test() {
  console.log('🧪 Тестирование форматов данных\n');
  
  const testFiles = [
    { name: 'SRT', file: 'test-data-srt.srt', parser: parseSRT },
    { name: 'VTT', file: 'test-data-vtt.vtt', parser: parseVTT },
    { name: 'CSV', file: 'test-data-csv.csv', parser: parseCSV }
  ];
  
  for (const { name, file, parser } of testFiles) {
    const filePath = path.join(__dirname, file);
    
    if (!fs.existsSync(filePath)) {
      console.log(`❌ ${name}: файл не найден (${filePath})`);
      continue;
    }
    
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      const segments = parser(content);
      
      console.log(`✅ ${name}:`);
      console.log(`   📊 Сегментов: ${segments.length}`);
      console.log(`   📝 Первый сегмент:`);
      console.log(`      Время: ${segments[0].startTime} --> ${segments[0].endTime}`);
      console.log(`      Текст: "${segments[0].text.substring(0, 80)}..."`);
      console.log(`   📝 Последний сегмент:`);
      const last = segments[segments.length - 1];
      console.log(`      Время: ${last.startTime} --> ${last.endTime}`);
      console.log(`      Текст: "${last.text.substring(0, 80)}..."`);
      
      // Статистика
      const totalWords = segments.reduce((sum, seg) => sum + seg.text.split(/\s+/).length, 0);
      const avgWords = Math.round(totalWords / segments.length);
      console.log(`   📈 Статистика:`);
      console.log(`      Всего слов: ${totalWords}`);
      console.log(`      Среднее слов на сегмент: ${avgWords}`);
      console.log(`      Размер файла: ${(content.length / 1024).toFixed(1)} KB`);
      console.log();
    } catch (error) {
      console.log(`❌ ${name}: ошибка парсинга - ${error.message}\n`);
    }
  }
}

test().catch(console.error);
