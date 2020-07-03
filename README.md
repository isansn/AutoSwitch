# AutoSwitch
No fee Autoswitcher HiveOS Flight Sheet for NiceHash

Редактируем config.conf, вставляя туда свои FARM_ID, RIG_ID из ссылки в браузере.<br>
Там же редактируем FACTORSHASH, формат такой что первым идет ALGO, затем FACTORS и YOUR_HASH.<br>
Там же добавляем алгоритм вписывая новую строку, с новым алгоритмом на этом все!, алга добавленна (если она есть на найсе).<br>
ALGO должно соответствовать названию алгоритма из найса https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info<br>
Создаем полетные листы с названиями Auto DaggerHashimoto и т.д. где DaggerHashimoto взято из поля title. <br>
Auto ALGO_FROM_NICE_TITLE<br>

При запуске<br>
Серым пишем алги у которых нет или hash или fs<br>
Красным у которых нет fs и есть hash или наоброт<br>
Желтым те что в работе<br>

Размещать в ~/Autoswitch/ или менять путь в auto.sh из source "$HOME/Autoswitch/config.conf" на source "$HOME/VASHSHSH_PUUUTTT/config.conf"<br>
Запускать ./auto.sh или screen -dmS auto ./auto.sh<br>
Чтобы посмотреть screen -r auto<br>
