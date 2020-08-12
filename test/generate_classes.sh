# удаляем старые файлы классов
rm -rf ./generated
# генерируем новые файлы классов
happymeal-1 xsd2code \
-m ru\\ilb \
-o ./generated \
-s ./schemas
