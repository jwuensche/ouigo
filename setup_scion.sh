#!/bin/bash

unavailable () {
    echo "The given nodes could not be allocated.
Have a check on the availability on the referenced clusters and try again."
    return 1
}

wait_for_node() {
    # 1 - Location string
    # 2 - Job id
    echo "Waiting for node in $1 to become ready.."
    while true
    do
        sleep 5
        state=$(curl -s -X GET https://api.grid5000.fr/3.0/sites/"$1"/jobs/"$2" | jq '.state')
        echo "Current state is $state"
        if [ "$state" == \"running\" ]
        then
            break
        fi
        echo "Node was not ready, waiting more.."
    done
    return 0
}

get_node_name() {
    # 1 - Location string
    # 2 - Job id
    name=$(curl -s https://api.grid5000.fr/3.0/sites/"$1"/jobs/"$2" | jq '.assigned_nodes[0]')
    echo "${name//\"/}"
}

setup_machine() {
    # 1 - machine address/name
    ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" root@"$1" "
    useradd scionlab
    usermod -aG sudo scionlab
    echo 'scionlab ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
    mkdir -p /home/scionlab/.ssh
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDN2DRwQzmsywlXfve9GSS0nxMkLZUADBxRelGODXjm++BN2y/09ADwHc9Z9ihFS1P1DgAo3H180UtM2I2mtxpkE0RVNLt9/6l8pP7x+VR9KOy08Tzp/hsf47zFHEZQoDUPV4refuBOX4eTG/gLnOxJjmYKloov8ArnGd3jnOgK/OIGtjIhg6a8200wqFYCiDoZzc68TMtToSs37jJgY2ERjL0AUk/eOpvcovNBpFnyykBbAEbj/Fh3C+xv/pg/AVOLadIwxdM/rwLfMuhQvJPCD4dq+8mJ33plw8F+CSa06ZfE+hnTr69T9i2/tYSOaTk/fYEGlCit/pWVDkoy1JO1N7BKX+ZH4idyMzIuE3jU0qIglNEHzvjAsSfUTOuyRIs3NAqX2IB20SEFIHmJK5/MVi31cTZkjfGF9OiGiitA3rIQBz5nhzEQWg/g3HI9Z/J144gEIyclskH6ugyT4iBNHk6TQS4KBAxdigGPqfykw9WwsfGIeeBaoH6lqtM6z93ICglBHACIjnUjyx/uXNU9x+6JakTb7PHN32+F4DuRv+IkTR2Q6XcqYBju4jjZkUHsf93leghjiBSFtXT2XF1QAjnUxkJi/vy59CwJXapCpUWIn2TxKSZCriuX4uyOxqfXc767QsfAmVIQT5osDtucmQScfBeuY9MPTsMsARI2oQ== scion-ansible-key
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTS3Euq1SXQ0wQsMrAdGgNhAJ7qHg/cSrDfCbZAOAj4/xOyEM5OFXrshtYDwbPqGA7Rtf4eq5ZCFSWaLh2aXSAr++I0X1av8rRXrizloWA2NjtkBVIJ/cuGty/lbNGFCa6KRgBOpd7c4lMTe/2AEAXM6azynMJJJ1eS8o+PZWcyEbCF36aOyF9kPoJ4by7gfXD3JGAXg3GltSBUURKzCvq9wCgvA9ZYApn+6Me1GrVbL0HhIm2mZXBVEYyqDSOQ9gjCz51K1eNp3kAabgxI5p9UEbJxN0emGHJt7PPOquZe9bbx/F7HxzzkOpatczyo45faj5u/s1y3vUohyy6E2GRSe/1rQVRxV7t4ENBUApt5Nd56fg0k/DGcnaVKnu0Kex0wY6jI4MwMS7DdB2cWsBkCCGwod8ybP7jDHLWC1siXY5bVA1ubCVeTNMgzpyWAgm8rqWlxtM6nqLTCb0oqPET7Y+q1ii8e+C5Y0Agd60Dq1Qi3TrSci2PsRI3hp6fuCawWVhpk/8yzCcAKKmfuCM8gTp+L7Y9IE99KBT1cfLMVNbA3FGC7SAJVCPSddCdxscwPZwAOfUSEKkQcWHqRO5PN32OogKq3liraCdVMfXlLOEGqpUJFnUnahQXLTHS+oHuHPPCDn/FjLAe2nivt7n0u4iTPQBhYFZIRHMmNCwEZQ== wirzf@inf.ethz.ch
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5RjfMFXQhu6rhiuq4wCgkb02YXrrTZtUW9NwQaqbveBlbDnzCdmXA9aPXq7E4yZttVFyQc+skiyZ/JlQGaDHUCWf02Jq0qIUxx458xPmzYG3MT4C/HPDw3DMMbr36xij9FuHt5litZ7874vjBYkbfPzh4WS/78+tt8gtS6HZG1I+jpdi2ucJIlha5Z52u6ItavYZiOWaASr8vC59kCd1OdtO3gowJPAz6/38WJ4TTzJrkoRSdaMZxoYh07xwg2Zn+ulKGZPoH33mwL2JtUPowFtBKe5YdYftbfT7n0jMBVMXYR6XsQ9VL/mpwTkSUe3W6hrsF+nZdk0hSt86QLvRRY7x07VkD25l3oyufiMW7ZdpWO87JI9OTgZluNFf1Vh6BucNrjiSxnKHnhHs4naOcLMBbfJLjDAaFe4bXZ3aHKw0wZZGpUApYKe/9nJqlP4lmZNlWoSZESXFndZiqQMixIoynNG7k4vuVp8zoXCmD6AduFRTv59p3g2tB0fHaFyuoIV3M4ffghdqayTJDRFn8KpeRfko/GR5Zo4/0GSLRTDiI5pScLb0EAbtoWJJFuJDt8wtbMUrPaN/i5QAhXOq9mvmAcnVigeWcIcrebA9EAv47y1ePrlyFh3l2eBr65MicrPjD+S9i4qxS7ryDsHJdd10WCuhX9rET/2QHaHsdlw== juan.garcia@inf.ethz.ch
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDsmeslOcAxeDlcjS6aCFTU0SJckSHNg/Y7AFQj0R1dtJ//SMGv0StYTTrV7fCeALjVhzji0BJeE6VdJs5BZFz3lLZhq/JoSGYX2DHfLTclvch73sH7gM/u9nr7uyTLPZNauPCV+7lXt7tLqxyBb/hcr/j4k44U4nUR/R2ChPL3l7HFv3Iaxa61vNVzL8MIqcCCxd8lqZ4gUfZuP5aSZTdVE6CJdKY6pPz0ch0deL2+ndQMr2O8dqZUEJHwA4WB9SSrWoezgxOHyLkENhOPOPMqFMKwn8VasWmtYywyj0NjFRPKJdhIrJy/DNjJXavOMlAIbwwTcbdJNbSpuDL4t0cz jkwon@ict-networks-192-168-001-003.fwd-v4.ethz.ch
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3LzEAkeZ4SNtTlHfEveGNGyxC4W0jWndjyckkxnCIIEXP9V6DWJIdUI3x+rrsAdolVBuoWogcW68+xogPg2xWkszKd3cEvPA3nDQWOzc4U4+a239dYb0YTgFKG/pDkcoS8qaRzuR0oveHXwdJeGMulAL111WZJ6xJk1cG5q+Eqh9cj61yzhw2a/XmEdaIEy/Yrgl5j6jrHjBVLww7rxdaSf9QWrDXVmuRDjD1F3knBeEOhAlK4kS8gL4rduqtwR6FybjiKkiqRKQk7hSB+aXgakmZ5DxEz0k/kqtSs+AWIPmZWS4JRO/JpieS//+wSS4MrM3ENWHKD7n0lJ/9Gbz8eirVAdb6SzOVAOXZw58A12TQ7JvD5YHr8hu96mEobt7GhvMOCRQAv7eddTZdqVNALTYFRxX//IYIJgvFhy2lUL6FDd+b9bzoUrIvCz6u2lx3a4j5jBeDxwJ5hZpB0Pc8i/iPB/wPZ0UfucirSM0/UvZgJWxnXu36LlZuIThSAMJJeT2iuuttl8OvY+wy/J1i1EaKcJTZu7IrYf3Q8FMmStTI0xe/LVoTJS7OKUGxn75YTaFbLre/N2kMvSXS4dL6zDHdP1t64gvl+t0Y7p5HLmq06anPhfHyVmHQ2q2e3eMsTjTASE7xNUs3K9jDLA6NuilVyDPXNO+UC7p2JETQlw== mateusz-kowalski:cardno:000608699130
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC257Sze025fiU139CRgKnXZO9IQKFBKM9KHKLasJq4DVf/I4phFKA/aAiEKuoic/j5u3bBvOCPKKnEITOoxcCifQyPwJw4dPhsotu7tBNSPWNo0hcBDu41MowqV/lSXEGldNQHoKTZZDc51oVF2XrHeR/rVCeddVEKTFTFoCi2a2WpfbM0wSZpGwCXXDnmfPKhK6lYHwjrJjluaEigC98kWYq0UKKFTDvvvXeomf6DeY1kT1eXASlh7+7Jmvm6XqSqYoWI56OsBXavuGODD114d2GphUsjIs59QtEhZ+rcqVtnWM9dwM+nWD5I/9qiBcYccVL+cnihoLomN3ZiVBb4mIJ9FS0mi08gRi29Z1atbjqw2TlYmAPYor8pdYqdTuLbvfSSTIHVfYOFuzH+kyHm4ZoRQX43wj+oWI0qX71NXqe3tsYufFGmbBDx6yLiQny/cbaDBh+omKdp4eLKI+NevX31o2peE2uq7zYs3j5b5VvE+9eiKaszyYPF1PJzGPU= netsec-awx
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwzZKvVxcsWFpJOgnKwfpmEC3t8LIAwQMIyjzS2lEQGtJa1jTay2p8oOH8J4YZc5fcNS0f94HuRBttTWbV5Vzs1GJs/o8bwUXfxKC+nqvzoLQs+AsQiXwnzz6JJxBN8CAtUZJ9Oi39kuDz3LHJMocM5VqTiIFVKBBpTyHrKapGZBH/vbJfoIcAM8LKl/BiV01hYTOVaq/LU/QyiUus0/Wl0QuY097KFQb3x6dgSfJo1+1oUJ3pfnTDsqWLNFkphTjZETZRdB53sGBIbWYumtGyVeY5scYTUPQ1iqbF8uWndyka/FE4LhR3ytboTlaSo6nCzr02uyP/kpy83yAgPwh3Q== hausheer@pc-hausheer
command=\"sudo scionlab-config\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnVk9YOZmt3JatkxZ6RcY/g/Sp4GjMTIcgrrYwzafZtaq6jDg1/aQCZovJjF+49j3K7T0oOjC7ncx5G/bE2g3Ay7bf2fzDHoiyK1PC4fYgw1YItYGGZxSkj6nQGu4IN4RWeTwwD3fnRzPuB44n71fe7G2Cnwc6i8sqtimowKledtVgi3IQ3ISXE2BZ5CnyCj9l81RYqPa3sBFyfSwwSPBz6IQvyYRFAF1h+XNI8qpEAoHqztaiuoRvV5kMxqyS3kDRxsEPuyR4JbDhGFs0l+b0K22XEl30a/vVRnMCVScx1AM/eJ3uELp4q/Vf6GXWtKQ/Hhbs3/Di1c67AIsRTaOX auto-deploy@scionlab.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC30UWfMgQcNFR4U2pGEqfcOQm2holD6kPjTLxYKevYOldtm4h5tSJCRfhCn7e0Bi0uTCQBJNLu+JWrje8OK8SKQypnXoKmcJqp8mN2v3w6iyX2xB9cFNP9F7zV8vdrWXPJB1NRMvunTmo2GwoNGASe5+ysBvfW2hIBuUN+8HrS9ZftRJFfoAlnaJFo6mnmLyCCo601xhQnSvoIib29GyPQ56qOeVVvXMEM3KU/eaZ0RP3TkEDSBMVEtak54yAx83u3SXE4Eopd5d0Ycn+t3jxWk7XMYzIytHXYrPtTAfTYCy+GnmoBE3kaDvs/zc+y3+WjfUMhcUXD3P8HbARvmMOv skamila-yknano/cardno:000610303896
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNO+fLmv6gywbDiYIstcNrlm9TgSuRWcxcTYrPgGefh2eJcYpbaQK1PrrwswuZpdFK0OBEtnlKLGKmhLafKsfY5EkZRqHKXQAiFvP9PTaU1k9roUGB4QUCOvXz8dMjSKVQ40hT36yxIXVE6qETK29lP0WHaN1MGyIHTpFOmidDmQxrJZYXKk1oJW4aw2mq7gK+AF0ii0Me8NtreEmsFXf2aKMXv22SuaL9S7w51W59jzE2ThGvT/Qwn89Vyrj3N51GKWxbznQ8IxYrq/h0pU2Xq8IhYiCfjJZ/sXYVHUxML+Of0KV2xTUjV87Ks5jxbpeWqSbA2F7TE+PPL6O8G5hz skamila-ykneo/cardno:000603638283
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKG2M3UbpyJGAF1xxjRrYvol+tcyxdMlgXCuaGiKTbuz matfrei@inf.ethz.ch
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmAztsnrE8u3IiKiPZ/ys+8eDr33BNO1FWlYDfVaaz69U/cdRUqDralByFZRjJunEazIIQ/lYqROeXmnYUW/+28/TVa3asdL4INjZoDayGpxj+zEAVVK3BU/vtU7W3q9lErapncl+MRsXmG/UexH7kGkxUo3T0IBEjAaQDAhfvA1OR426e+1GXFVlqppIJoG1awz2R9k1SSUGRns2DZ0ZYPb6YM1kwAp3MA+1d42VYlr3kSXPiLS/yIWbyH1KIZyOGR6VF79/av7WsH8ddQIunyaz4e0u9GZKS/Lrbp3sMl7264B48bJgfWEBKJ98WiLqsjA7cvOn3d4gCIlMt1hQ0t+QZXhQr0jfKxvK132/o7AvfMYH9N/1Krih5beRsgMPRUxIOhCMdBlbU5ChtffUHjyr03e+R9E27wT1AXRnJM70o3SUDwOQOSqGIv8gkluRYWS5fOSNhwD+B+SX4O0OjAfea2pyk3q7X97WYAYVvBHbtXj+mj0eSoNY5C7edos4qRL9rWnBln8kbfgrr2WGPSVzoCcRPtqVizcUyOfnZbU0MLPbUFf8lFsoGM/MO9DBHzXynjyxINHZwXTsMOyC0H6jFmBpvLdFwmTgL+Q9r7fCa8x4g/d4hE8DcBjvYmKf0aKVBUtqjmT0ysWIdxS7p7ii+EkB2SFlYcnD9LYE0+Q== matthias-frei:cardno:000610303898
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwpdjGYdUL498BpaIfARfrqoe8WBaaEO+b5vBef4xxV matzf@thumper
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQDaGpk/mUd0aDPYvLWbKvg8aDNkWbDw+xbuAjkHheXUmkNRAQqV2IlsNHGAtZRPH+SJlW+mRSUavVexcFPqyKb8VF9RYcdSWn+tjUvIoY81rIfO0gKYzr4G2ACWEV+vey1VlP7if8k3boNZbCG1EklwEnpl7P5fZoAsDhWJguh/9xIDEhq1bh6H7GfQJagcnS+rUvtXbqwqiPVDYKO3BJaALVukOcLdpxcEDQ5q4Qv5fNUBeQBliIKS7FrWsZNdVhJPi8TYWFmgyRGXzVj2EYX/vIcX0ezj7f5QIQacJUnSRg6eozYyO/4ESgRKjyn+toTENjrMChy7XjUIsqMWwshUX68OnzSBOhEgbkqCroYDVtHg4/OmgsVd9sJWWCT40Z0lfWVPISG/pCNrS4srUTyTyfA2SDyv+3WAWL4VG+lh/duFte2qKxRVOPKs/eg7gRUQJAGlYZBhl2FOWZGn5r60wX3Hh4zp0qEOyq2ULO8uCd4E46RqXL61kVHUL/v/yVmcB8XPmpAJaFJyASIzYNsre1oI6Axvhk8eUwWeZHKCl5tZckHh1D+Y+3fx9bkgsa12c44U1ErkRrLInK1uLdHuRMAN6DQpNJPcDzp/dWDzpBiZmIaW47mcQjgcjj+OEVoASX2s7QV6dis8wfg6yGl35bz3Xgd9YWigOPWFcRbTqeZCi2N0Wg6Fn9eoV9qBSrs+81t7LGRCGw7UtU4YDbMlIu6SnAEKFbGg2ylOvO5LEAdaMuWq14uC8HWigp2kLlkOlzE0ZBES5N65gLouAs44CcV7hj52sN4MdY4T7nh35Zrjks1h8nCcs5kvB2fE0imjD5R1YNHa37xQrHYajQ4xlYCXDiZkFX7O2gRT9gaLJ4NV8jcOIKRap7XgppcSswEV9X4MzmpyYkOcAVGqm/Bfeig46UOnY+TKn1VQVqSx9iWzCpyEWdHELh2ku1mH7yEWFlNQCfg0Y65KN6DTmQUvPzUSsS7lHDzvNdnyJ/g9dSgI9Vo7cOdM+pYPsMjFuDasUGdt9nlxjFOiv4clcIzuhGqhtOMhTNrSAdAqIQIc9Tv1p+R5b5nUDfYs5hCCylT/WBVfMPPowjYYsIzAGYOW6ka+kYLCWFPWjdPaQdq1LQXU+YIVbVZBoIyv50PD/IoWBNbeOBbHwqN4OHcp9Pobv449qrGz1VYvEFWLSGQNxS7RpNZQsbJ0w5FZaL9nEbNIWLJfr+6D78nHu7DycY0JCwmcKK7bmEVzgUIUfBPcHgl9+OsZE2MLxPTe61Pj/zhYE4UPnKQMd5xcHv0pd7p4TT40Vm4jkabdhBcTGpwmZTbxRfAGyNfpUyg0gjAQDlY3rMeZIXA0/Sh6X2cR4z51
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQCxIhVVb4r+7/OGpEkWCfSh8jSqjPQsb4h2Jorxw+tikaxPEk4tawjcVzn29aKqHZswMQ/Zhc0F7uHVAiv4JXWbVIqG3fhe1r1ZHWGmAbftF4aMDxUVMj0J4xyO/TPHJbEChqAhx6LZHxRjQi2wGMGWbYcaINEN6IExc5C+SBqs8DJSBeF0TTkGhRFkgAlp7kPSVlyGkys/uhGPzniTpjk3ROjHqlCnDPCqWqxXqFbWAgZYAt7MvxiED/IoVRZqeFuEWPni0rhB40JuIkqLumbrUDVnbIP7yBVCHpJWvW03we4dUGxzkcQAdAVXJY1Icn9k7+IK3d/fSIh4T70J3VsHXwuAMLG5tHiIqUnoxAjxy30Wj5HzvaQnP9TkP627HdUbD6EXyJrwwxzi6MdQR14IRQfauzCBraCArm22BKeaNh3bjAv4URCm7I2GlJnF0oofufjJ9AbGq/6xjnDhCJIdgaYWNjbPj2GZRQNK18xzxCPvpHZDg9k37Jpgp+gUG0bbA7AayFapMFE1v0OoqvwHPamDUavKkP49Kfog1yeW5NzWy9wrZyP+ZVYRuKqqK548SWIw1rYCv8OETJWTtmD6zgmFeCNXIqE+PYxd9lXpQHKSfBCvwUYhLjXL3zm8J3UGGXsZorUDjChTfXILSeMOoldahej7dGNrU9aqstixMKVO3zIYjCllF7yO/0FqmoHqpCX1dp9ExIqsdlQUoqBszR2diOyfJV1lijTUbGPI8qcQKCSjaE4FpCFrRekNvkZlmqvQGY1wFe+kpXKvkbxFWK2AdxAv0i3f/HaytjSbx9riaG6usp2G/xgVkJTHFkzf4qGzVN030O0kvvz5Zy8C8depsib7x8KqTFGEMTPtPALs0JhFV6jK/U7sT6KK8xqwhijrcX/F4xTXExIoGjwR2RYCwiNO8qxT6aoFAHk1mYBRizTIrTJRfni2YKvIU00MaVyVdOGUuRws1CZNQzJaaM4IMOxQY+JPKy1BqSz5fiZSc1eedo6hXrW7G2cFIEbVT39ospum9nlUEWF+g12yxhXiMK3NmxU47d3jpI55919o9fQeV52houqJBQfWxeZOnD89VluMK9T7oUjvoNLDTKpCQuovTlnw0ZEWGsjVDEffarf8DCL1RhhTXsy8k83pxHVPsKT5J7K4sb4BWPef18OtLq+qvssEAJa5wTALlYKTrpY8EswkTSwGp4sNMQ35ZcS7shQwKeL+XqkqsS1+s3+zt7fAcfacwzDI6sCCiJiKkIwkyLbpDXJYy1sdkQEt3JTPbdNrRcshFfgaR1kkYvFJydvPQK0l3/kNa2KGdfpmmEL1uBEV/1wnwQRpYGZpyfert08SdP9VTVuPwx+B jwuensch@byzantium' > /home/scionlab/.ssh/authorized_keys
    chown -R scionlab /home/scionlab
    chsh -s /bin/bash scionlab
"
}

wait_for_environment() {
    # 1 - machine address/name
    echo "Waiting for environment to be deployed"
    echo "This requires rebooting an bootstrapping the machines, this may take a while..."
    while true
    do
        sleep 10
        if ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o BatchMode=yes root@"$1" 'if [[ $(uname -a) =~ "Ubuntu" ]]; then exit 0; else exit 1; fi' > /dev/null 2>/dev/null
        then
            echo "Connecting possible, setting up..."
            setup_machine "$1"
            break
        fi
    done
    return 0
}

reserve_job() {
# 1 - job location
# 2 - cluster name
# 3 - first vlan id
# 4 - second vlan id

  # Get nodes and check availability there is a dummy `sleep infinity` command to keep the job alive
  ########################## NANCY

  # the $OAR_NODEFILE has to be evaluated on the machine itself, so disregard the shellcheck warning here
  node_result=$(curl -s https://api.grid5000.fr/3.0/sites/"$1"/jobs \
                  -X POST -H 'Content-Type: application/json' \
                  -d "{\"resources\":\"{eth_count>=2}/nodes=1,walltime=1\",\"command\":\"kadeploy3 -k -e ubuntu1804-x64-min -f \$OAR_NODEFILE; sleep infinity\", \"name\":\"machine_$3_$4\", \"types\":[\"deploy\"]}")

  vlan_job_id=$(curl -s https://api.grid5000.fr/3.0/sites/"$1"/jobs \
                  -X POST -H 'Content-Type: application/json' \
                  -d "{\"resources\":\"{type='kavlan-global'}/vlan=1,walltime=1\",\"command\":\"kavlan -d; curl -d \\\"{\\\\\\\"id\\\\\\\":\\\\\\\"\\\$(kavlan -V)\\\\\\\", \\\\\\\"sdx_vlan_id\\\\\\\":\\\\\\\"$3\\\\\\\"}\\\" -H \\\"Content-Type: application/json\\\" -X POST https://api.grid5000.fr/3.0/stitcher/stitchings; sleep infinity\", \"name\": \"vlan_$3\"}" | jq '.uid')

  node_id=$(echo "$node_result" | jq '.uid')
  echo "Reserved node in $1 (Job ID $node_id)"
  echo "Reserved VLAN in $1 (Job ID $vlan_job_id)"
  wait_for_node "$1" "$node_id"
  wait_for_node "$1" "$vlan_job_id"
  echo ""
  node_name=$(get_node_name "$1" "$node_id")
  echo "Got machine $node_name in $1 (Job ID $node_id)"

  echo "Adding interface to $node_name"
  sleep 10
  add_req="{\"nodes\":[\"$(echo "$node_name" | cut -d '.' -f 1)-eth1.$1.grid5000.fr\"]}"
  curl -s -d "$add_req" -X POST https://api.grid5000.fr/stable/sites/nancy/vlans/14 > /dev/null

  echo "Setting up machine $node_name"
  wait_for_environment "$node_name"
}

# reserve_job nancy gros 1293 1337
reserve_job lille chiclet 1294 0
