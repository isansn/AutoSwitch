# AutoSwitch
No fee Autoswitcher HiveOS Flight Sheet for NiceHash<br><br>
Редактируем conf.all.conf<br>
INTERVAL - интервал через который делается подсчет профита.<br>
MIN_DIFF - минимальный процент между топовым и текущим алгоритмами при привышении которого начнется отсчет.<br>
CALC_COUNT - число отсчетов, с профитом превышающим текущий на MIN_DIFF процент, по достижении которых произойдет переключение на топовый алгоритм. <br>
Например INTERVAL=10, MIN_DIFF=5 и CALC_COUNT=6.<br>
При таких настройках алгоритм переключится через 60сек т.е. после 6 раз по 10 секунд, если прибыльность алгоритма будет превышать текущий на 5%. <br>
Если происходит изменение топового алгоритма или его снижение ниже 5% то счетчик сбрасывается и отсчет начнется сначала.<br><br>
Редактируем config.conf или config.RIG_NAME_X.conf, вставляя туда свои FARM_ID, RIG_ID из ссылки в браузере.<br>
TOKEN получаем в вебморде хайва, щелкаем по аккаунту, ищем "Создать новый персональный" API-токен, создаем, жмем "Показать".<br>
FACTORSHASH первым идет ALGO, затем FACTORS, потом YOUR_HASH и не обязательное поле FS_NAME.<br>
FS_NAME это имя полетного листа, если его не указывать, то на hive оно должно соответствовать формату: <br>Autoswitch NAME_ALGO_FROM_NICE_TITLE (Autoswitch DaggerHashimoto) взято из поля title https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info. <br>
В конфиге оно должно быть так же скопировано из поля title.<br>
FACTORS делитель для расчета прибыльности, в основном подбирается в ручную.<br>
Там же добавляем алгоритм вписывая новую строку, с новым алгоритмом, все алга добавленна (если она есть на найсе).<br>

При запуске<br>
Серым для алгов у которых в конфиге hash 0<br>
Красным те алги для которых не найдены полетные листы<br>
Желтым те между которыми будет работать автосвичер<br>
Если в списке, подсчета топовых, алгоритм не виден, значит его название не соответствует списку из найса.<br>
Если в списке, подсчета топовых, профит алгоритма равен 0, значит не настроен factores для этого алгоритма.<br>

Запуск командой ./run.sh start &<br>
Подойдет для одного рига необходимо изменить только config.conf и conf.all.conf.<br>
При таком запуске, запустится одна копия с применением config.conf.<br>
Просмотреть можно командой screen -r auto<br>
<br>
Запуск командой ./run.sh start all &<br>
При таком запуске, запустится столько копий, сколько конфигов в формате config.RIG_NAME_X.conf. Просмотреть можно командой screen -r auto-RIG_NAME_X<br> 
<br>
Если после запуска в screen -r нет auto значит скорее всего скрипт не смог подключиться к хайву проверьте FARM_ID, RIG_ID, TOKEN.<br>
Так же можно посмотреть лог cat /dev/shm/autoswitch-isans-log <br>

Остановка командой ./run.sh stop<br>
<br>
Конфиги и полетные листы подгружаются при запуске.<br>
Для перезапуска команда ./run.sh stop не обязательна, при старте скрипт сам завершит предидущие процессы и начнет работать с новыми настройками. <br>
<br>
Установка<br>
git clone https://github.com/isansn/AutoSwitch.git<br>
cd AutoSwitch<br>
Для начала меняем только RIG_ID, FARM_ID и TOKEN<br>
nano config.conf <br>
./run.sh start &<br>
screen -r auto<br>
<br>
Добавлена возможность называть полетные листы.<br>
Пример в config.eth_from_ethermine_to_nice.conf дает возможность переключать риг с ethermine на nice (или ZIL), только тогда когда профит на nice по DaggerHashimoto превышает KAWPOW, GrinCuckatoo32, BeamV3, GrinCuckatoo31, Cuckaroom и обратно на ethermine.<br>
<br>
Автозапуск в HiveOS<br>
echo "@reboot sleep 60 && /home/user/AutoSwitch/run.sh start 1 >/dev/null 2>/dev/null" >> /hive/etc/crontab.root<br>
или<br>
echo "@reboot sleep 60 && /home/user/AutoSwitch/run.sh start all 1 >/dev/null 2>/dev/null" >> /hive/etc/crontab.root<br>
<br>
Автозапуск в нормальной ОС<br>
sudo echo "@reboot sleep 60 && /home/user/AutoSwitch/run.sh start 1 >/dev/null 2>/dev/null" >> /var/spool/cron/crontabs/$USER<br>
или<br>
sudo echo "@reboot sleep 60 && /home/user/AutoSwitch/run.sh start all 1 >/dev/null 2>/dev/null" >> /var/spool/cron/crontabs/$USER<br>
<br>
Или через crontab -e вставить строку @reboot sleep 60 && /home/user/AutoSwitch/run.sh start 1 >/dev/null 2>/dev/null
<br><br>

