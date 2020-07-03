# AutoSwitch
No fee Autoswitcher HiveOS Flight Sheet for NiceHash

Редактируем config.conf, вставляя туда свои FARM_ID, RIG_ID из ссылки в браузере.<br>
Там же редактируем FACTORSHASH, формат такой что первым идет ALGO, затем FACTORS и YOUR_HASH.
Там же добавляем алгоритм вписывая новую строку, с новым алгоритмом на этом все!, алга добавленна (если она есть на найсе).
ALGO должно соответствовать названию алгоритма из найса https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info
Создаем полетные листы с названиями Auto DaggerHashimoto и т.д. где DaggerHashimoto взято из поля title. 
Auto ALGO_FROM_NICE_TITLE

При запуске
Серым пишем алги у которых нет или hash или fs
Красным у которых нет fs и есть hash или наоброт
Желтым те что в работе

Размещать в ~/Autoswitch/ или менять путь в auto.sh из source "$HOME/Autoswitch/config.conf" на source "$HOME/VASHSHSH_PUUUTTT/config.conf"
Запускать ./auto.sh или screen -dmS auto ./auto.sh
Чтобы посмотреть screen -r auto
