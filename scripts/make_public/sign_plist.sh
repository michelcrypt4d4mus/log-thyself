# https://www.cmdsec.com/unified-logs-enable-private-data/?utm_source=share&utm_medium=ios_app&utm_name=iossmf
/usr/bin/security find-identity -p codesigning -v

# Use one of the certificates listed like so to sign the profile
# I have used the example output above to fill in this example command
/usr/bin/security cms -S -Z "22DC6A88856D5C082954D1F01H7EJ12FA4264E47" -i "/Path/to/unsigned/profile.mobileconfig" -o "/output/path/for/new/signed/profile.mobileconfig"
