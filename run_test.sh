case $TEST in
  "TEST_ALL")
        # These tests fail on 14.04 which travis uses
        newt test all -e net/oic/test,net/ip/mn_socket/test
     ;;
  "BUILD_TARGETS")
        # Without suppressing output, travis complains that the log is too big
        # Without output, travis terminates a job that doesn't print out anything in a few minutes
        newt build -q -l info all
     ;;
  "BUILD_BLINKY")
        ${TRAVIS_BUILD_DIR}/ci/test_build_blinky.sh
     ;;
  *)  exit 1
     ;;
esac

