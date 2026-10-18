# Источники изображений рецептов

Каждая карточка рецепта хранит собственный идентификатор TheMealDB (`idMeal`) и
собственную фотографию этого блюда (`strMealThumb`). Соответствие «название ↔ фото»
задаётся записью рецепта, а не позицией в списке, поэтому сортировка, поиск и
фильтры не могут его нарушить. Файлы пересоздаются скриптом
`scripts/fetch_recipe_images.mjs`.

## TheMealDB

API: https://www.themealdb.com/api/json/v1/1/lookup.php?i=<idMeal>
Документация: https://www.themealdb.com/docs_api_guide.php

Бесплатный ключ TheMealDB предназначен для разработки, обучения и личных проектов.
Для публичного коммерческого приложения нужен supporter-ключ (см. раздел
«Production note» в документации) и проверка условий использования изображений.

| Рецепт в приложении | Файл | strMeal | idMeal | strMealThumb |
| --- | --- | --- | --- | --- |
| Блины гречневые | `53080_blini.jpg` | Blini Pancakes | 53080 | https://www.themealdb.com/images/media/meals/0206h11699013358.jpg |
| Шакшука с фетой | `52963_shakshuka.jpg` | Shakshuka | 52963 | https://www.themealdb.com/images/media/meals/g373701551450225.jpg |
| Банановые панкейки | `52855_banana_pancakes.jpg` | Banana Pancakes | 52855 | https://www.themealdb.com/images/media/meals/sywswr1511383814.jpg |
| Овсяные панкейки с клубникой | `53331_oatmeal_pancakes.jpg` | Oatmeal pancakes | 53331 | https://www.themealdb.com/images/media/meals/c400ok1764439058.jpg |
| Яйца Бенедикт с лососем | `52962_eggs_benedict_salmon.jpg` | Salmon Eggs Eggs Benedict | 52962 | https://www.themealdb.com/images/media/meals/1550440197.jpg |
| Английский завтрак | `52896_full_english.jpg` | Full English Breakfast | 52896 | https://www.themealdb.com/images/media/meals/sqrtwu1511721265.jpg |
| Борщ с говядиной | `53311_borsch.jpg` | Borsch | 53311 | https://www.themealdb.com/images/media/meals/804v1j1764367088.jpg |
| Бефстроганов | `52834_beef_stroganoff.jpg` | Beef stroganoff | 52834 | https://www.themealdb.com/images/media/meals/svprys1511176755.jpg |
| Паста с курицей и овощами | `52796_chicken_alfredo.jpg` | Chicken Alfredo Primavera | 52796 | https://www.themealdb.com/images/media/meals/syqypv1486981727.jpg |
| Паста карбонара | `52982_carbonara.jpg` | Spaghetti alla Carbonara | 52982 | https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg |
| Шаурма с курицей и йогуртовым соусом | `53218_chicken_shawarma.jpg` | Chicken Shawarma with homemade garlic herb yoghurt sauce | 53218 | https://www.themealdb.com/images/media/meals/hcg6l91763596970.jpg |
| Салат с курицей, киноа и фетой | `53011_quinoa_greek_salad.jpg` | Chicken Quinoa Greek Salad | 53011 | https://www.themealdb.com/images/media/meals/k29viq1585565980.jpg |
| Фалафель в пите с тахини | `53091_falafel_pita.jpg` | Falafel Pita Sandwich with Tahini Sauce | 53091 | https://www.themealdb.com/images/media/meals/ae6clc1760524712.jpg |
| Запечённый лосось с фенхелем и томатами | `52959_baked_salmon_fennel.jpg` | Baked salmon with fennel & tomatoes | 52959 | https://www.themealdb.com/images/media/meals/1548772327.jpg |
| Лосось терияки | `52773_salmon_teriyaki.jpg` | Honey Teriyaki Salmon | 52773 | https://www.themealdb.com/images/media/meals/xxyupu1468262513.jpg |
| Говядина с брокколи | `53366_beef_broccoli.jpg` | Beef and Broccoli Stir-Fry | 53366 | https://www.themealdb.com/images/media/meals/m0p0j81765568742.jpg |
| Курица терияки с рисом | `52772_teriyaki_chicken_rice.jpg` | Teriyaki Chicken Casserole | 52772 | https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg |
| Лазанья болоньезе | `52844_lasagne.jpg` | Lasagne | 52844 | https://www.themealdb.com/images/media/meals/wtsvxx1511296896.jpg |
| Матар панир | `52865_matar_paneer.jpg` | Matar Paneer | 52865 | https://www.themealdb.com/images/media/meals/xxpqsy1511452222.jpg |
| Курица кацу-карри | `52820_katsu_curry.jpg` | Katsu Chicken curry | 52820 | https://www.themealdb.com/images/media/meals/vwrpps1503068729.jpg |
| Хумус с йогуртом | `53269_hummus.jpg` | Hummus | 53269 | https://www.themealdb.com/images/media/meals/gpon5u1763801180.jpg |
| Авокадо-дип с молодым картофелем | `53107_avocado_dip.jpg` | Avocado dip with new potatoes | 53107 | https://www.themealdb.com/images/media/meals/flrajf1762341295.jpg |
| Банановые оладьи | `53351_banana_fritters.jpg` | Jamaican Banana Fritters | 53351 | https://www.themealdb.com/images/media/meals/ul2uy31764794321.jpg |
| Шоколадный мусс с авокадо | `52853_chocolate_mousse.jpg` | Chocolate Avocado Mousse | 52853 | https://www.themealdb.com/images/media/meals/uttuxy1511382180.jpg |
| Чизкейк Нью-Йорк | `52858_new_york_cheesecake.jpg` | New York cheesecake | 52858 | https://www.themealdb.com/images/media/meals/swttys1511385853.jpg |
| Крамбл с яблоком и ежевикой | `52893_apple_crumble.jpg` | Apple & Blackberry Crumble | 52893 | https://www.themealdb.com/images/media/meals/xvsurr1511719182.jpg |

## Собственные проверенные записи

Этих блюд нет в TheMealDB, поэтому для них нет и «похожего» блюда из API.
У каждой записи отдельный документированный источник и лицензия.

| Рецепт в приложении | Файл | Источник | Автор | Лицензия |
| --- | --- | --- | --- | --- |
| Сырники с ягодами | `syrniki.jpg` | [Wikimedia Commons — File:Syrniki with fruits.jpg](https://commons.wikimedia.org/wiki/File:Syrniki_with_fruits.jpg) — «Syrniki with sour cream, candied fruits and raspberry» | Off-shell | CC BY-SA 4.0 |
