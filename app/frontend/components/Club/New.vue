<template>
    <ClubModal ref="modal" :club="modalClub" :isNew="true" @save="saveClub" />
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'
import ClubModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const modalClub = ref({
    club_name: '',
    territory: '',
    representative: '',
    email: '',
    phone: '',
    alternative_club_name: '',
    runners_count: 0
})
const modal = ref(null)


function createNew() {
    modal.value.show()
}

onMounted(() => {
    createNew()
})

function saveClub(clubData, done) {
    axios.post('/clubs.json', { club: clubData }).then(res => {
        window.location = "/clubs?sorting[direction]=desc";
    })
}
</script>
