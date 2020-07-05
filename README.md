# AutoSwitch
No fee Autoswitcher HiveOS Flight Sheet for NiceHash

Редактируем config.conf, вставляя туда свои FARM_ID, RIG_ID из ссылки в браузере.<br>
Там же редактируем FACTORSHASH, формат такой что первым идет ALGO, затем FACTORS и YOUR_HASH.<br>
Там же добавляем алгоритм вписывая новую строку, с новым алгоритмом на этом все!, алга добавленна (если она есть на найсе).<br>
ALGO должно соответствовать названию алгоритма из найса https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info<br>
Создаем полетные листы с названиями Autoswitch DaggerHashimoto и т.д. где DaggerHashimoto взято из поля title. <br>
Autoswitch ALGO_FROM_NICE_TITLE<br>

При запуске<br>
Серым для алгов у которых в конфиге hash 0<br>
Красным те алги для которых не найдены полетные листы<br>
Желтым те между которыми будет работать автосвичер<br>
Если в списке после подсчета топовых алгоритм не виден, значит его название не соответствует списку из найса.<br>

Размещать в ~/Autoswitch/ или менять путь в auto.sh из source "$HOME/Autoswitch/config.conf" на source "$HOME/VASHSHSH_PUUUTTT/config.conf"<br>
Запускать ./auto.sh или screen -dmS auto ./auto.sh<br>
Чтобы посмотреть screen -r auto<br>
