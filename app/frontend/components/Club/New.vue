<template>
    <Create ref="create" @save="saveClub" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Club</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveClub() {
    window.location = "/clubs?sorting[direction]=desc";
}
</script>
