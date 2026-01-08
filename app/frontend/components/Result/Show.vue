<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> <a :href="`/runners/${result.membership?.runner_id}`">{{result.membership?.runner.runner_name}} {{result.membership?.runner.surname}}</a> </h1>
        <p><strong>Club: </strong><a :href="`/clubs/${result.membership?.club_id}`">{{result.membership?.club.club_name}}</a></p>
        <hr class="my-4">
        <p><strong>Data: </strong>{{result.date}}</p>
        <p><strong>Competiția: </strong><a :href="`/competitions/${result.group?.competition_id}`">{{result.group?.competition.competition_name}}</a></p>
        <p><strong>Grupa: </strong><a :href="`/groups/${result.group_id}`">{{result.group?.group_name}}</a></p>
        <hr class="my-4">
        <p><strong>Locul: </strong>{{result.place}}</p>
        <p><strong>Timpul: </strong>{{formatResultTime(result.time)}}</p>
        <hr class="my-4">
        <p><strong>Categoria Îndeplinită: </strong><a :href="`/categories/${result.category_id}`">{{result.category?.category_name}}</a></p>
        <p v-show="result.status"><strong>Îndeplinire: </strong>{{result.status}}</p>
        <hr class="my-4">
        <p v-show="result.wre_points"><strong>Wre Puncte: </strong>{{result.wre_points}}</p>
        <p v-show="result.ecn_points"><strong>Ecn Puncte: </strong>{{result.ecn_points}}</p>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editCategory(category)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteCategory(category.id)">Sterge</button>
    </p>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
const result = ref({})
const resultId = ref("")


onMounted(() => {
    resultId.value = window.location.pathname.split('/').pop();
    getData();
})

async function getData() {
    const res = await axios.get(`/results/${resultId.value}.json`)
    result.value = res.data;
}

function formatResultTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}
</script>
