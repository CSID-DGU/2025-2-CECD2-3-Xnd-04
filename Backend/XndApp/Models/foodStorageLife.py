from django.db import models

class FoodStorageLife(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=15, unique=True)
    storage_life = models.SmallIntegerField()

    def __str__(self):
        return self.name

# 보관기한 데이터
# INSERT INTO xnddb.xndapp_foodstoragelife (name, storage_life) VALUES ('닭다리살', 2), ('배추', 7), ('소고기', 4), ('신김치', 30), ('양배추', 14), ('표고버섯', 7), ('삼겹살', 3), ('돼지고기', 3), ('닭가슴살', 2), ('콩나물', 4), ('깻잎', 5), ('생강청', 180), ('두부', 3), ('차돌박이', 4), ('당근', 14), ('부추', 5), ('토마토', 7), ('계란', 21), ('양송이버섯', 7), ('애호박', 7), ('새송이', 7), ('명태살', 2), ('크래미', 5)