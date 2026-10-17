#!/usr/bin/env node
// Downloads the photo of every recipe in the bundled catalog from TheMealDB.
//
// The catalog stores, for each recipe, the TheMealDB `idMeal` and the photo that
// belongs to that exact `idMeal` (`strMealThumb`). Nothing is matched by list
// position: run this script and every recipe keeps its own photo.
//
// Usage: node scripts/fetch_recipe_images.mjs
// Output: assets/images/recipes/<idMeal>_<slug>.jpg + assets/images/recipes/SOURCES.md

import { writeFile } from 'node:fs/promises';
import path from 'node:path';

const API = 'https://www.themealdb.com/api/json/v1/1/lookup.php?i=';
const OUT_DIR = path.join('assets', 'images', 'recipes');

// idMeal -> { file, title }. `title` is only used in SOURCES.md.
const MEALS = [
  { id: '53080', file: '53080_blini.jpg', title: 'Блины гречневые' },
  { id: '52963', file: '52963_shakshuka.jpg', title: 'Шакшука с фетой' },
  { id: '52855', file: '52855_banana_pancakes.jpg', title: 'Банановые панкейки' },
  { id: '53331', file: '53331_oatmeal_pancakes.jpg', title: 'Овсяные панкейки с клубникой' },
  { id: '52962', file: '52962_eggs_benedict_salmon.jpg', title: 'Яйца Бенедикт с лососем' },
  { id: '52896', file: '52896_full_english.jpg', title: 'Английский завтрак' },
  { id: '53311', file: '53311_borsch.jpg', title: 'Борщ с говядиной' },
  { id: '52834', file: '52834_beef_stroganoff.jpg', title: 'Бефстроганов' },
  { id: '52796', file: '52796_chicken_alfredo.jpg', title: 'Паста с курицей и овощами' },
  { id: '52982', file: '52982_carbonara.jpg', title: 'Паста карбонара' },
  { id: '53218', file: '53218_chicken_shawarma.jpg', title: 'Шаурма с курицей и йогуртовым соусом' },
  { id: '53011', file: '53011_quinoa_greek_salad.jpg', title: 'Салат с курицей, киноа и фетой' },
  { id: '53091', file: '53091_falafel_pita.jpg', title: 'Фалафель в пите с тахини' },
  { id: '52959', file: '52959_baked_salmon_fennel.jpg', title: 'Запечённый лосось с фенхелем и томатами' },
  { id: '52773', file: '52773_salmon_teriyaki.jpg', title: 'Лосось терияки' },
  { id: '53366', file: '53366_beef_broccoli.jpg', title: 'Говядина с брокколи' },
  { id: '52772', file: '52772_teriyaki_chicken_rice.jpg', title: 'Курица терияки с рисом' },
  { id: '52844', file: '52844_lasagne.jpg', title: 'Лазанья болоньезе' },
  { id: '52865', file: '52865_matar_paneer.jpg', title: 'Матар панир' },
  { id: '52820', file: '52820_katsu_curry.jpg', title: 'Курица кацу-карри' },
  { id: '53269', file: '53269_hummus.jpg', title: 'Хумус с йогуртом' },
  { id: '53107', file: '53107_avocado_dip.jpg', title: 'Авокадо-дип с молодым картофелем' },
  { id: '53351', file: '53351_banana_fritters.jpg', title: 'Банановые оладьи' },
  { id: '52853', file: '52853_chocolate_mousse.jpg', title: 'Шоколадный мусс с авокадо' },
  { id: '52858', file: '52858_new_york_cheesecake.jpg', title: 'Чизкейк Нью-Йорк' },
  { id: '52893', file: '52893_apple_crumble.jpg', title: 'Крамбл с яблоком и ежевикой' },
];

// Dishes that TheMealDB does not have. They must use their own verified photo,
// never a look-alike: a separate record, a separate documented image.
const LOCAL = [
  {
    file: 'syrniki.jpg',
    title: 'Сырники с ягодами',
    source: 'Wikimedia Commons — File:Syrniki with fruits.jpg',
    page: 'https://commons.wikimedia.org/wiki/File:Syrniki_with_fruits.jpg',
    image:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Syrniki_with_fruits.jpg/960px-Syrniki_with_fruits.jpg',
    author: 'Off-shell',
    license: 'CC BY-SA 4.0',
    note: 'Syrniki with sour cream, candied fruits and raspberry',
  },
];

const jpegSize = (buf) => {
  let i = 2;
  while (i < buf.length) {
    if (buf[i] !== 0xff) return null;
    const marker = buf[i + 1];
    const length = buf.readUInt16BE(i + 2);
    if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) {
      return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    }
    i += 2 + length;
  }
  return null;
};

const entries = [];

for (const meal of MEALS) {
  const response = await fetch(API + meal.id);
  if (!response.ok) throw new Error(`TheMealDB lookup failed for ${meal.id}: ${response.status}`);
  const payload = await response.json();
  const found = payload.meals?.[0];
  if (!found) throw new Error(`TheMealDB has no meal with id ${meal.id}`);
  if (found.idMeal !== meal.id) {
    throw new Error(`TheMealDB returned ${found.idMeal} instead of ${meal.id}`);
  }

  const image = await fetch(found.strMealThumb);
  if (!image.ok) throw new Error(`Photo download failed for ${meal.id}: ${image.status}`);
  const buffer = Buffer.from(await image.arrayBuffer());
  const size = jpegSize(buffer);
  if (!size) throw new Error(`Photo of ${meal.id} is not a valid JPEG`);
  await writeFile(path.join(OUT_DIR, meal.file), buffer);

  entries.push({
    title: meal.title,
    file: meal.file,
    meal: found.strMeal,
    id: found.idMeal,
    category: found.strCategory,
    area: found.strArea,
    url: found.strMealThumb,
    size: `${size.width}×${size.height}`,
    bytes: buffer.length,
  });
  console.log(`ok ${meal.id} ${found.strMeal} -> ${meal.file} (${size.width}×${size.height})`);
}

for (const local of LOCAL) {
  const image = await fetch(local.image);
  if (!image.ok) throw new Error(`Photo download failed for ${local.file}: ${image.status}`);
  const buffer = Buffer.from(await image.arrayBuffer());
  const size = jpegSize(buffer);
  if (!size) throw new Error(`Photo ${local.file} is not a valid JPEG`);
  await writeFile(path.join(OUT_DIR, local.file), buffer);
  console.log(`ok local ${local.file} (${size.width}×${size.height})`);
}

const header = `# Источники изображений рецептов

Каждая карточка рецепта хранит собственный идентификатор TheMealDB (\`idMeal\`) и
собственную фотографию этого блюда (\`strMealThumb\`). Соответствие «название ↔ фото»
задаётся записью рецепта, а не позицией в списке, поэтому сортировка, поиск и
фильтры не могут его нарушить. Файлы пересоздаются скриптом
\`scripts/fetch_recipe_images.mjs\`.

## TheMealDB

API: https://www.themealdb.com/api/json/v1/1/lookup.php?i=<idMeal>
Документация: https://www.themealdb.com/docs_api_guide.php

Бесплатный ключ TheMealDB предназначен для разработки, обучения и личных проектов.
Для публичного коммерческого приложения нужен supporter-ключ (см. раздел
«Production note» в документации) и проверка условий использования изображений.

| Рецепт в приложении | Файл | strMeal | idMeal | strMealThumb |
| --- | --- | --- | --- | --- |
${entries
  .map(
    (e) =>
      `| ${e.title} | \`${e.file}\` | ${e.meal} | ${e.id} | ${e.url} |`,
  )
  .join('\n')}

## Собственные проверенные записи

Этих блюд нет в TheMealDB, поэтому для них нет и «похожего» блюда из API.
У каждой записи отдельный документированный источник и лицензия.

| Рецепт в приложении | Файл | Источник | Автор | Лицензия |
| --- | --- | --- | --- | --- |
${LOCAL.map(
  (l) =>
    `| ${l.title} | \`${l.file}\` | [${l.source}](${l.page}) — «${l.note}» | ${l.author} | ${l.license} |`,
).join('\n')}
`;

await writeFile(path.join(OUT_DIR, 'SOURCES.md'), header, 'utf8');
console.log(`wrote ${path.join(OUT_DIR, 'SOURCES.md')}`);
