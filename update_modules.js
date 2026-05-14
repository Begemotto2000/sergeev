const fs = require('fs');
const path = '/home/ubuntu/sergeev_digitization_system/client/src/pages/TechSupport/CompletionControlPanel.tsx';
let content = fs.readFileSync(path, 'utf-8');

// Replace the blocks array
const oldBlocks = `    {
      id: 'reviews',
      name: 'Разборы с Иваном',
      type: 'Видео',
      totalSize: '10 × 3-4 часа = ~30-40 часов',
      uploaded: 0,
      total: 10,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'library',
      name: 'Библиотека дополнительных материалов',
      type: 'PDF/Документы',
      totalSize: '~100+ документов',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'other-courses',
      name: 'Другие обучающие курсы',
      type: 'Видео/Курсы',
      totalSize: 'Разное',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },`;

const newBlocks = `    {
      id: 'module-6',
      name: 'Модуль 6: CHATPLACE',
      type: 'Видео',
      totalSize: '~3-4 часа',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'module-7',
      name: 'Модуль 7: РАЗБОРЫ С ИВАНОМ',
      type: 'Видео',
      totalSize: '10 × 3-4 часа = ~30-40 часов',
      uploaded: 0,
      total: 10,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'module-8',
      name: 'Модуль 8: БОНУСНЫЕ ЭФИРЫ',
      type: 'Видео',
      totalSize: '~10-15 часов',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'module-9',
      name: 'Модуль 9: ЗАПИСЬ СОЗВОНОВ С НАСТАВНИКОМ АНДРЕЕМ',
      type: 'Видео',
      totalSize: '~10-15 часов',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'additional-materials',
      name: 'Дополнительные материалы к обучению',
      type: 'PDF/Документы',
      totalSize: '~100+ документов',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'content-camp',
      name: 'ИВАН СЕРГЕЕВ КОНТЕНТ-ЛАГЕРЬ',
      type: 'Видео/Материалы',
      totalSize: 'Разное',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },
    {
      id: 'other-courses',
      name: 'ДРУГИЕ КУРСЫ И ПРОГРАММЫ ОБУЧЕНИЯ',
      type: 'Видео/Курсы',
      totalSize: 'Разное',
      uploaded: 0,
      total: 100,
      percentage: 0,
      status: 'pending',
    },`;

content = content.replace(oldBlocks, newBlocks);
fs.writeFileSync(path, content);
console.log('✅ CompletionControlPanel обновлена');
