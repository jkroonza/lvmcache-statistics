= LVM Cache Statistics

lvmcache-statistics.sh displays the LVM cache statistics
in a user friendly manner

Copyright (C) 2014 Armin Hammer 
Copyright (C) 2023 Jaco Kroon

This program is free software: you can redistribute it and/or modify 
it under the terms of the GNU General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at 
your option) any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
for more details.

You should have received a copy of the GNU General Public License along 
with this program. If not, see http://www.gnu.org/licenses/.

History:
20141220 hammerar, initial version
20230803 jkroon:
* amended to auto-detect and report on all cache volumes.
* work even if there are snapshots of cached volumes (albeit with extra -real after LV name)
