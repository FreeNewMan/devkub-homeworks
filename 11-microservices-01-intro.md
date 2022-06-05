# Домашнее задание к занятию "11.01 Введение в микросервисы"

## Задача 1: Интернет Магазин

Руководство крупного интернет магазина у которого постоянно растёт пользовательская база и количество заказов рассматривает возможность переделки своей внутренней ИТ системы на основе микросервисов. 

Вас пригласили в качестве консультанта для оценки целесообразности перехода на микросервисную архитектуру. 

Опишите какие выгоды может получить компания от перехода на микросервисную архитектуру и какие проблемы необходимо будет решить в первую очередь.

**Ответ:**
Микросервисная архитектура применяется с целью ускорения разработки и быстрой доставки до пользователей новой функциональности приложений путем создания множества самодостаточных(слабосвязанных) мини-сервисов взаимодействующих между собой по единым стандартам для всех в то время как внутреннее устройство и стек технологий может быть любой.

Существующий проект, в данном случае интернет-магазин, перед тем как "пилить" его на микросервисы, Целесообразно сначала ответить детально на вопрос "Зачем?" Не должно быть целью просто разделение ради разделения на сервисы. Важно понимать что конкретно хотим улучшить, чем пожертвовать ради достижения результата. 

Затем поискать в нем узкие места, которые снижают эффективность работы из-за каких-то лишних взаимодействий между разными командами отвечающие за работу проекта. 

Затем определить возможные границы, по которым можно определить будущие сервисы. Например, разделить  приложение по структуре компании или по группам сотрудников с определенной компетенцией. Также целесообразно выделить части приложения с находящиеся под большой нагрузкой в отдельные сервисы, чтобы была возможность их горизонтально масштабировать с учетом нагрузки (именно, «тяжелые участки» вместо всего приложения целиком).

Например, главную страницу, витрину, лендиг выделить в о отдельные сервисы. Они должны открываться максимально быстро. Здесь стоит применить технологии кэширования, базы данных ориентированные на быстрое чтение и хранение данные в оперативной памяти.

```
---